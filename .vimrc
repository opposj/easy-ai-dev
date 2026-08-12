if $BUILD_TIER !=# 'lite'
	if empty(glob('~/.vim/autoload/plug.vim')) | execute "silent !curl -fLo ~/.vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim" | endif
	autocmd VimEnter * if len(filter(values(g:plugs), '!isdirectory(v:val.dir)')) | PlugInstall --sync | source $MYVIMRC | endif
	call plug#begin()
		Plug '/home/linuxbrew/.linuxbrew/opt/fzf'
		Plug 'junegunn/fzf.vim'
	call plug#end()
endif

set tabstop=4 shiftwidth=4 autoindent hls is wildoptions=pum ignorecase smartcase termguicolors

silent! nnoremap <silent> <unique> <leader>yw :<c-u>call system('base64 -w 0 <bar> xargs -I {} printf "\033]52;c;%s\a" {} > /dev/tty', "<c-r><c-w>")<cr>
silent! nnoremap <silent> <unique> <leader>y<s-w> :<c-u>call system('base64 -w 0 <bar> xargs -I {} printf "\033]52;c;%s\a" {} > /dev/tty', "<c-r><c-a>")<cr>
silent! nnoremap <silent> <unique> <leader>yy :<c-u>call system('base64 -w 0 <bar> xargs -I {} printf "\033]52;c;%s\a" {} > /dev/tty', getline('.'))<cr>
silent! vnoremap <silent> <unique> <leader>y :<c-u>call system('base64 -w 0 <bar> xargs -I {} printf "\033]52;c;%s\a" {} > /dev/tty', execute("'<,'>p")[1:])<cr>
