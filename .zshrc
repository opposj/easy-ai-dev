[[ $TUI == 0 ]] && return

rfv() (
	RELOAD='reload:echo {q} | xargs rg --column --color=always --smart-case || :'
	OPENER='if [[ $FZF_SELECT_COUNT -eq 0 ]]; then { vim {1} +{2}; } else { vim +cw -q {+f}; } fi'
	fzf --disabled --ansi --multi --bind "start:$RELOAD" --bind "change:$RELOAD" --bind "enter:become:$OPENER" --bind "ctrl-o:execute:$OPENER" --bind 'alt-a:select-all,alt-d:deselect-all,ctrl-/:toggle-preview' --delimiter : --preview 'bat --style=full --color=always --highlight-line {2} {1}' --preview-window '~4,+{2}+4/3,<80(up)' --query "$*"
)

y() {
	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
	command yazi "$@" --cwd-file="$tmp"
	IFS= read -r -d '' cwd < "$tmp"
	[ "$cwd" != "$PWD" ] && [ -d "$cwd" ] && builtin cd -- "$cwd"
	rm -f -- "$tmp"
}

plugins=(git zsh-autosuggestions zsh-syntax-highlighting zsh-bash-completions-fallback)

source "$ZSH/oh-my-zsh.sh"
source <(fzf --zsh)
eval "$(zoxide init zsh)"
eval "$(starship init zsh)"

[[ $AGENTS == *forgecode* ]] && { if [[ -z "$_FORGE_PLUGIN_LOADED" ]]; then eval "$(forge zsh plugin)"; fi; if [[ -z "$_FORGE_THEME_LOADED" ]]; then eval "$(forge zsh theme)"; fi }

bindkey '^U' backward-kill-line

source $ZSH/custom/plugins/zsh-bash-completions-fallback/zsh-bash-completions-fallback.plugin.zsh
