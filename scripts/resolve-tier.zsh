typeset -A LANG_MAP=(c '' cpp '' ruby '' fortran '' perl '' python 'uv python' js 'bun node' tsc 'bun node' go 'go' rust 'rustup' sql 'duckdb' php 'php' lua 'lua luarocks' elixir 'elixir' erlang 'erlang' zig 'zig' swift 'swift' r 'r' clojure 'clojure' java 'openjdk' lisp 'sbcl' dart 'dart-sdk' ada '' julia 'julia' kotlin 'kotlin')
typeset -A AGENT_DEP=(forgecode '' tmuxai '' codex '' claude '' opencode '' pi 'node' omp '' jcode '' hermes 'node' crush '' grok '' reasonix '' droid '' goose '' aider '' copilot '' cline 'bun node' codebuddy '' kilo '' kimi 'node' qwen 'node' mcode 'bun node' qoder 'bun node' prime 'node uv' deepagents 'uv' openhands 'uv' deepcode 'bun node' atomic '' letta '')
typeset -U CORE_FORMULAE=(iproute2 socat make jq ripgrep fd tgrep gh ruby unzip sevenzip file-formula vim neurosnap/tap/zmx mise gum bubblewrap)
typeset -U TUI_FORMULAE=(less rlwrap tmux zellij herdr hunk bat eza starship lazygit fastfetch fzf zoxide yazi tlrc bash-completion@2 wl-clipboard hyperfine man-db texinfo universal-ctags gdb ffmpeg-full imagemagick-full poppler resvg try yt-dlp)
typeset -U ALL_LANG=( ${(ko)LANG_MAP} )
typeset -U ALL_AGENT=( ${(ko)AGENT_DEP} )
typeset -U LANGS=() AGENTS=() DEPS=() LANG_FORMULAE=()

case $1 in lite) TUI=${2:-0}; LANGS+=(python tsc); AGENTS+=(forgecode);; default) TUI=${2:-1}; LANGS+=(python tsc go rust sql); AGENTS+=(forgecode codex opencode pi);; pro) TUI=${2:-1}; LANGS+=(python tsc go rust sql lua clojure lisp zig r); AGENTS+=(forgecode codex opencode pi crush jcode cline kilo omp);; full) TUI=${2:-1}; LANGS+=(all); AGENTS+=(all);; *) TUI=${2:-0};; esac
(( TUI )) || TUI_FORMULAE=()

LANGS+=( ${=${3//,/ }} ); AGENTS+=( ${=${4//,/ }} ); (( ${LANGS[(I)all]} )) && LANGS=(${LANGS#all} $ALL_LANG); (( ${AGENTS[(I)all]} )) && AGENTS=(${AGENTS#all} $ALL_AGENT)

for a in $AGENTS; do [[ -n ${AGENT_DEP[$a]} ]] && DEPS+=(${=AGENT_DEP[$a]}); done; for l in $LANGS; do [[ -n ${LANG_MAP[$l]} ]] && LANG_FORMULAE+=(${=LANG_MAP[$l]}); done

QUICKLISP=$(( ${LANGS[(I)lisp]} > 0 )); ALIRE=$(( ${LANGS[(I)ada]} > 0 ))

for k in TUI LANGS AGENTS DEPS CORE_FORMULAE TUI_FORMULAE LANG_FORMULAE QUICKLISP ALIRE; print -r -- "$k='${(P)k}'"
