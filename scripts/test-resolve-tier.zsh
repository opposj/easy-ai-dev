#!/usr/bin/env zsh
# -----------------------------------------------------------------------------
# Thorough spec tests for scripts/resolve-tier.zsh
#
#   run:  zsh scripts/test-resolve-tier.zsh
#
# The resolver is invoked exactly as the Dockerfile `tier` stage does:
#   zsh resolve-tier.zsh "$TIER" "$TUI" "$LANGS" "$AGENTS" "$TOOLS"
#
# The LANG_MAP at the top of the resolver is the source of truth: LANGS is
# expressed in its KEYS (language names), LANG_FORMULAE in its VALUES
# (formulae). Key -> formulae translations:
#   python -> uv python    js/tsc -> bun node    rust -> rustup
#   sql -> duckdb          lisp -> sbcl          lua -> lua luarocks
#   java -> openjdk        dart -> dart-sdk      go -> go, r -> r, ...
#   julia -> julia         kotlin -> kotlin
#   csharp -> dotnet       deno -> deno
#   ocaml -> ocaml         scala -> scala
#   c cpp ruby fortran perl ada moonbit -> (no formulae)
#
# Expected behaviour (spec):
#   TIER       TUI  LANG (keys)                                AGENT
#   ---------- ---- ------------------------------------------ --------------------------------
#   (empty)    0    -                                          -
#   lite       0    python tsc                                  fx
#   default    1    python tsc go rust sql                      fx forgecode codex opencode pi
#   pro        1    python tsc go rust sql                      fx forgecode codex opencode pi
#                    lua clojure lisp zig r                    crush jcode cline kilo omp
#   full       1    all (node included, no bun->node shim)     all
#
#   TOOLS is an independent vocabulary, unseeded by TIER and deduplicated like
#   the other lists. The only tool is the self-versioned `cuda`, whose version
#   must be complete (<major>.<minor>.<patch>):
#     cuda@13.4.2 -> CUDA_IMAGE=nvidia/cuda:13.4.2-devel-ubuntu24.04
#     `cuda` without a version, an incomplete or non-numeric version, or any
#     other token (including `all`) is fatal (rc 1, empty stdout); when two
#     different cuda@ specs are given, the last one wins
#
#   Hard rules:
#     - explicit TUI overrides the tier default
#     - LANG/AGENT are merged on top of the tier and deduplicated
#     - only the keyword `all` is accepted; `everything` is deprecated and is
#       treated as a plain (unknown) token
#     - tokens outside the LANG_MAP keys install nothing (e.g. `node`, `bun`
#       alone are not keys — use js/tsc for bun+node)
#     - agent language deps are exported in DEPS (pi/hermes/kimi/qwen ->
#       node; cline/deepcode/mcode/qoder -> bun node; prime -> node uv;
#       openhands/deepagents/opensquilla -> uv)
#     - output is dash-sourceable and every value is a bare space-separated
#       word list (the Dockerfile `brewed` stage builds
#       "formulae=$CORE_FORMULAE $TUI_FORMULAE $LANG_FORMULAE" and the
#       `agent_env` stage matches on `" $LANGS "` with space padding)
#     - QUICKLISP/ALIRE/MOONBIT are emitted as 0/1 flags (1 iff lisp/ada/moonbit
#       in LANGS) so the Dockerfile needs no glob matching
#     - TOOLS is echoed verbatim; CUDA_IMAGE stays empty unless cuda is
#       requested (agent_env then streams that image with crane and installs
#       the CUDA toolkit from it)
#     - unlike LANGS/AGENTS, unknown TOOLS tokens fail the resolver instead of
#       flowing through to the Dockerfile
# -----------------------------------------------------------------------------

typeset -gi PASS=0 FAIL=0
typeset -gA ISSUES=(comma 0 dash 0)
typeset -g TMP=${TMPDIR:-/tmp}
typeset -g RESOLVER=${0:A:h}/resolve-tier.zsh
typeset -g ZSH_BIN=${commands[zsh]:-zsh}

# --- pinned constants (space-joined) ----------------------------------------
typeset -g CORE_EXP='iproute2 socat make jq ripgrep fd tgrep gh ruby unzip sevenzip file-formula vim neurosnap/tap/zmx mise gum bubblewrap crane pkgconf'
typeset -g TUI_EXP='less rlwrap tmux zellij herdr hunk bat eza starship lazygit fastfetch fzf zoxide yazi tlrc bash-completion@2 wl-clipboard hyperfine man-db texinfo universal-ctags gdb ffmpeg-full imagemagick-full poppler resvg try yt-dlp'
typeset -g ALL_LANG_EXP='ada c clojure cpp csharp dart deno elixir erlang fortran go java js julia kotlin lisp lua moonbit ocaml perl php python r ruby rust scala sql swift tsc zig'
typeset -g ALL_AGENT_EXP='aider atomic claude cline codebuddy codex copilot crush deepagents deepcode droid forgecode fx goose grok hermes jcode kilo kimi letta mcode mimo omp opencode openhands opensci opensquilla pi prime qoder qwen reasonix tmuxai zerostack'
typeset -g FULL_LANG_F='clojure dotnet dart-sdk deno elixir erlang go openjdk bun node julia kotlin sbcl lua luarocks ocaml php uv python r rustup scala duckdb swift zig'

# --- helpers -----------------------------------------------------------------
norm() { print -r -- ${(j: :)${=${1//,/ }}} }   # canonical space-joined form

# rt_run tier tui lang agent [tools] -> sets G_* globals
rt_run() {
  G_ERRF=$TMP/rt.err.$$
  G_OUT=$(zsh "$RESOLVER" "$1" "$2" "$3" "$4" "${5:-}" 2>$G_ERRF)
  G_RC=$?
  G_ERR=$(<$G_ERRF)
  rm -f $G_ERRF
  local TUI LANGS AGENTS TOOLS CUDA_IMAGE DEPS CORE_FORMULAE TUI_FORMULAE LANG_FORMULAE QUICKLISP ALIRE MOONBIT
  eval "$G_OUT"
  G_TUI=$TUI G_LANGS=$LANGS G_AGENTS=$AGENTS G_TOOLS=$TOOLS G_DEPS=$DEPS
  G_CORE=$CORE_FORMULAE G_TUIF=$TUI_FORMULAE G_LANGF=$LANG_FORMULAE
  G_QUICKLISP=$QUICKLISP G_ALIRE=$ALIRE G_MOONBIT=$MOONBIT
  G_CUDA_IMAGE=$CUDA_IMAGE
}

ok()   { ((PASS++)) }
bad()  { ((FAIL++)); print -r -- "FAIL $1"; print -r -- "  expect: [$2]"; print -r -- "  actual: [$3]" }

cmp() { # label expected actual  (content compare, separator-normalised)
  local label=$1 e=$(norm "$2") a=$(norm "$3")
  if [[ $e == $a ]]; then ok; else bad "$label" "$e" "$a"; fi
}

# verify tier tui lang agent exp_tui exp_langs exp_agents exp_deps exp_tuif exp_langf [tools] [exp_cuda_image] [exp_tools]
verify() {
  local name=${funcstack[2]}
  rt_run "$1" "$2" "$3" "$4" "${11:-}"

  (( G_RC == 0 )) || bad "$name rc" 0 $G_RC
  [[ -z $G_ERR ]] || bad "$name stderr" '<empty>' "$G_ERR"

  # contract: values must be bare space-separated word lists (no commas);
  # identical for every case, so failures are aggregated in the summary
  [[ $G_OUT == *,* ]] && ((ISSUES[comma]++))

  # contract: output must be dash-sourceable (as consumed by brewed/agent_env)
  local srcf=$TMP/rt.src.$$
  print -r -- $G_OUT > $srcf
  sh -c ". $srcf" 2>/dev/null || ((ISSUES[dash]++))
  rm -f $srcf

  cmp "$name TUI"           "$5"  "$G_TUI"
  cmp "$name LANGS"         "$6"  "$G_LANGS"
  cmp "$name AGENTS"        "$7"  "$G_AGENTS"
  cmp "$name DEPS"          "$8"  "$G_DEPS"
  cmp "$name TUI_FORMULAE"  "$9"  "$G_TUIF"
  cmp "$name LANG_FORMULAE" "$10" "$G_LANGF"
  cmp "$name CORE_FORMULAE" "$CORE_EXP" "$G_CORE"

  # derived flags: QUICKLISP/ALIRE/MOONBIT must mirror LANGS membership
  local exp_ql=0 exp_al=0 exp_mb=0
  [[ " $G_LANGS " == *" lisp "* ]] && exp_ql=1
  [[ " $G_LANGS " == *" ada "* ]] && exp_al=1
  [[ " $G_LANGS " == *" moonbit "* ]] && exp_mb=1
  cmp "$name QUICKLISP" "$exp_ql" "$G_QUICKLISP"
  cmp "$name ALIRE" "$exp_al" "$G_ALIRE"
  cmp "$name MOONBIT" "$exp_mb" "$G_MOONBIT"

  # tool selection: TOOLS is compared in its deduplicated form ($13, defaults
  # to the raw input $11); the cuda spec expands into CUDA_IMAGE
  cmp "$name TOOLS"      "${13:-${11:-}}" "$G_TOOLS"
  cmp "$name CUDA_IMAGE" "${12:-}" "$G_CUDA_IMAGE"

  # dedupe invariant: no list may repeat an entry
  local v
  for v in G_LANGS G_AGENTS G_TOOLS G_DEPS G_TUIF G_LANGF G_CORE; do
    local -a arr uniq
    arr=(${(P)v})
    uniq=(${(u)arr})
    if (( ${#arr} == ${#uniq} )); then ok; else ((FAIL++)); print -r -- "FAIL $name duplicates in $v: [${arr[*]}]"; fi
  done
}

# verify_error tier tui lang agent tools exp_rc exp_msg — fatal paths must
# exit non-zero, explain themselves on stderr and emit nothing usable on stdout
verify_error() {
  local name=${funcstack[2]}
  rt_run "$1" "$2" "$3" "$4" "$5"
  (( G_RC == $6 )) || bad "$name rc" $6 $G_RC
  [[ $G_ERR == *"$7"* ]] || bad "$name stderr" "*$7*" "$G_ERR"
  [[ -z $G_OUT ]] || bad "$name stdout" '<empty>' "$G_OUT"
}

# --- tiers -------------------------------------------------------------------
t_tier_empty()   { verify '' '' '' '' 0 '' '' '' '' '' }
t_tier_lite()    { verify lite '' '' '' 0 'python tsc' fx '' '' 'uv python bun node' }
t_tier_default() { verify default '' '' '' 1 'python tsc go rust sql' 'fx forgecode codex opencode pi' node "$TUI_EXP" 'uv python bun node go rustup duckdb' }
t_tier_pro()     { verify pro '' '' '' 1 'python tsc go rust sql lua clojure lisp zig r' 'fx forgecode codex opencode pi crush jcode cline kilo omp' 'node bun' "$TUI_EXP" 'uv python bun node go rustup duckdb lua luarocks clojure sbcl zig r' }
t_tier_full()    { verify full '' '' '' 1 "$ALL_LANG_EXP" "$ALL_AGENT_EXP" 'bun node uv' "$TUI_EXP" "$FULL_LANG_F" }

# --- TUI override (explicit TUI wins over the tier default) ------------------
t_tui_lite_on()     { verify lite 1 '' '' 1 'python tsc' fx '' "$TUI_EXP" 'uv python bun node' }
t_tui_default_on()  { verify default 1 '' '' 1 'python tsc go rust sql' 'fx forgecode codex opencode pi' node "$TUI_EXP" 'uv python bun node go rustup duckdb' }
t_tui_default_off() { verify default 0 '' '' 0 'python tsc go rust sql' 'fx forgecode codex opencode pi' node '' 'uv python bun node go rustup duckdb' }
t_tui_pro_off()     { verify pro 0 '' '' 0 'python tsc go rust sql lua clojure lisp zig r' 'fx forgecode codex opencode pi crush jcode cline kilo omp' 'node bun' '' 'uv python bun node go rustup duckdb lua luarocks clojure sbcl zig r' }
t_tui_full_off()    { verify full 0 '' '' 0 "$ALL_LANG_EXP" "$ALL_AGENT_EXP" 'bun node uv' '' "$FULL_LANG_F" }
t_tui_empty_on()    { verify '' 1 '' '' 1 '' '' '' "$TUI_EXP" '' }
t_tui_empty_off()   { verify '' 0 '' '' 0 '' '' '' '' '' }

# --- LANG merge / dedupe / mapping -------------------------------------------
t_lang_merge_php()     { verify default '' php '' 1 'python tsc go rust sql php' 'fx forgecode codex opencode pi' node "$TUI_EXP" 'uv python bun node go rustup duckdb php' }
t_lang_dedupe()        { verify default '' 'python go' '' 1 'python tsc go rust sql' 'fx forgecode codex opencode pi' node "$TUI_EXP" 'uv python bun node go rustup duckdb' }
t_lang_dedupe_comma()  { verify lite '' 'python, tsc' '' 0 'python tsc' fx '' '' 'uv python bun node' }
t_lang_comma()         { verify '' '' 'php, lua, zig' '' 0 'php lua zig' '' '' '' 'php lua luarocks zig' }
t_lang_java()          { verify '' '' java '' 0 java '' '' '' openjdk }
t_lang_java_clojure()  { verify '' '' 'clojure java' '' 0 'clojure java' '' '' '' 'clojure openjdk' }
t_lang_dart()          { verify '' '' dart '' 0 dart '' '' '' dart-sdk }
t_lang_csharp()        { verify '' '' csharp '' 0 csharp '' '' '' dotnet }
t_lang_deno()          { verify '' '' deno '' 0 deno '' '' '' deno }
t_lang_ada()           { verify '' '' ada '' 0 ada '' '' '' '' }
t_lang_always_present(){ verify '' '' 'c cpp perl fortran ruby' '' 0 'c cpp perl fortran ruby' '' '' '' '' }
t_lang_node_not_a_key(){ verify '' '' node '' 0 node '' '' '' '' }
t_lang_bun_not_a_key() { verify '' '' bun '' 0 bun '' '' '' '' }
t_lang_js()            { verify '' '' js '' 0 js '' '' '' 'bun node' }
t_lang_tsc()           { verify '' '' tsc '' 0 tsc '' '' '' 'bun node' }
t_lang_rust()          { verify '' '' rust '' 0 rust '' '' '' rustup }
t_lang_sql()           { verify '' '' sql '' 0 sql '' '' '' duckdb }
t_lang_python()        { verify '' '' python '' 0 python '' '' '' 'uv python' }
t_lang_lisp()          { verify '' '' lisp '' 0 lisp '' '' '' sbcl }
t_lang_go()            { verify '' '' go '' 0 go '' '' '' go }
t_lang_lua()           { verify '' '' lua '' 0 lua '' '' '' 'lua luarocks' }
t_lang_ocaml()         { verify '' '' ocaml '' 0 ocaml '' '' '' ocaml }
t_lang_scala()         { verify '' '' scala '' 0 scala '' '' '' scala }
t_lang_moonbit()       { verify '' '' moonbit '' 0 moonbit '' '' '' '' }
t_lang_moonbit_merge() { verify lite '' moonbit '' 0 'python tsc moonbit' fx '' '' 'uv python bun node' }

# --- all / deprecated everything ---------------------------------------------
t_lang_all()             { verify '' '' all '' 0 "$ALL_LANG_EXP" '' '' '' "$FULL_LANG_F" }
t_lang_all_repeated()    { verify '' '' 'all all' 'all all' 0 "$ALL_LANG_EXP" "$ALL_AGENT_EXP" 'bun node uv' '' "$FULL_LANG_F" }
t_lang_all_on_default()  { verify default '' all '' 1 'python tsc go rust sql ada c clojure cpp csharp dart deno elixir erlang fortran java js julia kotlin lisp lua moonbit ocaml perl php r ruby scala swift zig' 'fx forgecode codex opencode pi' node "$TUI_EXP" 'uv python bun node go rustup duckdb clojure dotnet dart-sdk deno elixir erlang openjdk julia kotlin sbcl lua luarocks ocaml php r scala swift zig' }
t_lang_node_on_full()    { verify full '' node '' 1 'node ada c clojure cpp csharp dart deno elixir erlang fortran go java js julia kotlin lisp lua moonbit ocaml perl php python r ruby rust scala sql swift tsc zig' "$ALL_AGENT_EXP" 'bun node uv' "$TUI_EXP" "$FULL_LANG_F" }
t_lang_everything_deprecated() { verify '' '' everything '' 0 everything '' '' '' '' }

# --- AGENT merge / dedupe / deps ---------------------------------------------
t_agent_dedupe()        { verify '' '' '' 'forgecode forgecode' 0 '' forgecode '' '' '' }
t_agent_merge_pi()      { verify default '' '' pi 1 'python tsc go rust sql' 'fx forgecode codex opencode pi' node "$TUI_EXP" 'uv python bun node go rustup duckdb' }
t_agent_merge_comma()   { verify '' '' '' 'pi, cline' 0 '' 'pi cline' 'node bun' '' '' }
t_agent_node_deps()     { verify '' '' '' 'pi hermes kimi qwen qoder' 0 '' 'pi hermes kimi qwen qoder' 'node bun' '' '' }
t_agent_bun_deps()      { verify '' '' '' 'cline deepcode' 0 '' 'cline deepcode' 'bun node' '' '' }
t_agent_mcode()         { verify '' '' '' mcode 0 '' mcode 'bun node' '' '' }
t_agent_mimo()          { verify '' '' '' mimo 0 '' mimo '' '' '' }
t_agent_codebuddy()     { verify '' '' '' codebuddy 0 '' codebuddy '' '' '' }
t_agent_prime()         { verify '' '' '' prime 0 '' prime 'node uv' '' '' }
t_agent_uv_deps()       { verify '' '' '' 'openhands deepagents' 0 '' 'openhands deepagents' uv '' '' }
t_agent_mixed()         { verify '' '' '' 'pi cline prime' 0 '' 'pi cline prime' 'node bun uv' '' '' }
t_agent_atomic()        { verify '' '' '' atomic 0 '' atomic '' '' '' }
t_agent_letta()         { verify '' '' '' letta 0 '' letta '' '' '' }
t_agent_zerostack()   { verify '' '' '' zerostack 0 '' zerostack '' '' '' }
t_agent_opensci()     { verify '' '' '' opensci 0 '' opensci '' '' '' }
t_agent_fx()          { verify '' '' '' fx 0 '' fx '' '' '' }
t_agent_opensquilla() { verify '' '' '' opensquilla 0 '' opensquilla uv '' '' }
t_agent_all()           { verify '' '' '' all 0 '' "$ALL_AGENT_EXP" 'bun node uv' '' '' }
t_agent_all_on_default(){ verify default '' '' all 1 'python tsc go rust sql' 'fx forgecode codex opencode pi aider atomic claude cline codebuddy copilot crush deepagents deepcode droid goose grok hermes jcode kilo kimi letta mcode mimo omp openhands opensci opensquilla prime qoder qwen reasonix tmuxai zerostack' 'node bun uv' "$TUI_EXP" 'uv python bun node go rustup duckdb' }
t_agent_bogus()         { verify '' '' '' bogus 0 '' bogus '' '' '' }
t_agent_everything_deprecated() { verify '' '' '' everything 0 '' everything '' '' '' }

# --- TOOLS: self-versioned cuda tool (spec -> CUDA_* contract) ----------------
t_cuda()                 { verify '' '' '' '' 0 '' '' '' '' '' cuda@13.4.2 nvidia/cuda:13.4.2-devel-ubuntu24.04 }
t_cuda_12()              { verify '' '' '' '' 0 '' '' '' '' '' cuda@12.9.1 nvidia/cuda:12.9.1-devel-ubuntu24.04 }
t_cuda_patch_zero()      { verify '' '' '' '' 0 '' '' '' '' '' cuda@13.3.0 nvidia/cuda:13.3.0-devel-ubuntu24.04 }
t_cuda_dedupe()          { verify '' '' '' '' 0 '' '' '' '' '' 'cuda@13.4.2,cuda@13.4.2' nvidia/cuda:13.4.2-devel-ubuntu24.04 cuda@13.4.2 }
t_cuda_comma()           { verify '' '' '' '' 0 '' '' '' '' '' 'cuda@13.4.2, cuda@13.4.2' nvidia/cuda:13.4.2-devel-ubuntu24.04 cuda@13.4.2 }
t_cuda_with_tier()       { verify lite '' '' '' 0 'python tsc' fx '' '' 'uv python bun node' cuda@12.9.1 nvidia/cuda:12.9.1-devel-ubuntu24.04 }
t_cuda_with_lang_agent() { verify '' '' lisp pi 0 lisp pi node '' sbcl cuda@13.4.2 nvidia/cuda:13.4.2-devel-ubuntu24.04 }
t_cuda_with_bare_lang()  { verify '' '' 'python c' '' 0 'python c' '' '' '' 'uv python' cuda@13.4.2 nvidia/cuda:13.4.2-devel-ubuntu24.04 }
t_cuda_missing_version() { verify_error '' '' '' '' cuda 1 'Illegal CUDA version' }
t_cuda_empty_version()   { verify_error '' '' '' '' 'cuda@' 1 'Illegal CUDA version' }
t_cuda_incomplete()      { verify_error '' '' '' '' cuda@13.4 1 'Illegal CUDA version' }
t_cuda_extra_part()      { verify_error '' '' '' '' cuda@13.4.2.1 1 'Illegal CUDA version' }
t_cuda_non_numeric()     { verify_error '' '' '' '' cuda@latest 1 'Illegal CUDA version' }
t_cuda_last_wins()       { verify '' '' '' '' 0 '' '' '' '' '' 'cuda@13.4.2 cuda@12.9.1' nvidia/cuda:12.9.1-devel-ubuntu24.04 }
t_tools_unknown()        { verify_error '' '' '' '' vulkan 1 'Unknown tool: vulkan' }
t_tools_unknown_mixed()  { verify_error '' '' '' '' 'cuda@13.4.2,vulkan' 1 'Unknown tool: vulkan' }
t_tools_all_rejected()   { verify_error '' '' '' '' all 1 'Unknown tool: all' }

# --- unknown tier -------------------------------------------------------------
t_tier_unknown()          { verify garbage '' '' '' 0 '' '' '' '' '' }
t_tier_unknown_merged()   { verify garbage '' php pi 0 php pi node '' php }
t_tier_unknown_tui_on()   { verify garbage 1 '' '' 1 '' '' '' "$TUI_EXP" '' }

main() {
  local -a tests=(
    t_tier_empty t_tier_lite t_tier_default t_tier_pro t_tier_full
    t_tui_lite_on t_tui_default_on t_tui_default_off t_tui_pro_off t_tui_full_off t_tui_empty_on t_tui_empty_off
    t_lang_merge_php t_lang_dedupe t_lang_dedupe_comma t_lang_comma t_lang_java t_lang_java_clojure
    t_lang_dart t_lang_csharp t_lang_deno t_lang_ada t_lang_always_present t_lang_node_not_a_key t_lang_bun_not_a_key
    t_lang_js t_lang_tsc t_lang_rust t_lang_sql t_lang_python t_lang_lisp t_lang_go t_lang_lua t_lang_ocaml t_lang_scala
    t_lang_moonbit t_lang_moonbit_merge
    t_lang_all t_lang_all_repeated t_lang_all_on_default t_lang_node_on_full t_lang_everything_deprecated
    t_agent_dedupe t_agent_merge_pi t_agent_merge_comma t_agent_node_deps t_agent_bun_deps
    t_agent_mcode t_agent_mimo t_agent_codebuddy t_agent_prime t_agent_uv_deps t_agent_mixed t_agent_atomic t_agent_letta t_agent_zerostack t_agent_opensci t_agent_fx t_agent_opensquilla t_agent_all t_agent_all_on_default
    t_agent_bogus t_agent_everything_deprecated
    t_cuda t_cuda_12 t_cuda_patch_zero t_cuda_dedupe t_cuda_comma
    t_cuda_with_tier t_cuda_with_lang_agent t_cuda_with_bare_lang
    t_cuda_missing_version t_cuda_empty_version t_cuda_incomplete t_cuda_extra_part t_cuda_non_numeric t_cuda_last_wins
    t_tools_unknown t_tools_unknown_mixed t_tools_all_rejected
    t_tier_unknown t_tier_unknown_merged t_tier_unknown_tui_on
  )
  local t
  for t in $tests; do $t; done

  print -r -- ""
  print -r -- "== summary =="
  print -r -- "content assertions:  $PASS pass / $FAIL fail"
  if (( ISSUES[comma] + ISSUES[dash] > 0 )); then
    (( ISSUES[comma] )) && print -r -- "contract violation:  comma-joined values in $ISSUES[comma] cases (IFS leak) — \"formulae=\" expands to one token, \"case \" \$LANGS \"\" padding never matches"
    (( ISSUES[dash] )) && print -r -- "contract violation:  output not dash-sourceable in $ISSUES[dash] cases"
  else
    print -r -- "output contract:     all cases pass"
  fi
  if (( FAIL == 0 && ISSUES[comma] == 0 && ISSUES[dash] == 0 )); then
    print -r -- "ALL GREEN"
  else
    print -r -- "BUGS FOUND — see failures above"
  fi
  (( FAIL == 0 && ISSUES[comma] == 0 && ISSUES[dash] == 0 ))
}

main
