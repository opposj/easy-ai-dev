addpath() {
	setopt localoptions extendedglob
	local pre= post="$2" to="$1"; [[ -d "$1" || -n "$3" ]] && pre="$1" post= to="$2"; local base="${(P)to}"; base="${base##:##}"; base="${base%%:##}"
	[[ -n "$pre" && "$base" != *"$pre"* ]] && export "$to"="$pre":"$base" && return 0
	[[ -n "$post" && "$base" != *"$post"* ]] && export "$to"="$base":"$post" && return 0
	return 1
}

[[ -z $HOMEBREW_PREFIX ]] && eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
addpath /home/linuxbrew/.linuxbrew/opt/glibc/sbin PATH
addpath /home/linuxbrew/.linuxbrew/opt/glibc/bin PATH
addpath /home/linuxbrew/.linuxbrew/lib/ruby/gems/4.0.0/bin PATH 1
addpath /home/linuxbrew/.linuxbrew/opt/rustup/bin PATH 1
addpath /root/.bun/bin PATH 1

typeset -U PATH FPATH
