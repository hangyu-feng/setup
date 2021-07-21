
if has("win16") || has("win32")
  set shell=pwsh
  let vimplugdir = "$home/vimfiles/autoload/plug.vim"
elseif has("unix")
  let vimplugdir = "~/.vim/autoload/plug.vim"
endif

" automated vim-plug download
if empty(glob(vimplugdir))
  " `.` for string concatenation
  execute 'silent !curl --create-dirs -fLo ' . vimplugdir . ' https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
  autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

call plug#begin('~/.vim/bundle')

Plug 'junegunn/vim-plug'
Plug 'junegunn/goyo.vim'

Plug 'morhetz/gruvbox'
" Plugin 'lifepillar/vim-gruvbox8'

" plugin on GitHub repo
Plug 'tpope/vim-fugitive'

" some defaults
Plug 'tpope/vim-sensible'
runtime! 'plugin/sensible.vim'  " run this plugin earlier to override settings

" Plugin 'zivyangll/git-blame.vim'

Plug 'scrooloose/nerdtree'
let NERDTreeShowHidden=1
map <C-n> :NERDTreeToggle<CR>

Plug 'scrooloose/nerdcommenter'
map - <plug>NERDCommenterToggle
" Add spaces after comment delimiters by default
let g:NERDSpaceDelims = 1
" Use compact syntax for prettified multi-line comments
let g:NERDCompactSexyComs = 1
" Align line-wise comment delimiters flush left instead of following code indentation
let g:NERDDefaultAlign = 'left'
" Add your own custom formats or override the defaults
let g:NERDCustomDelimiters = { 'c': { 'left': '/**','right': '*/' } }
" Allow commenting and inverting empty lines (useful when commenting a region)
let g:NERDCommentEmptyLines = 1
" Enable trimming of trailing whitespace when uncommenting
let g:NERDTrimTrailingWhitespace = 1
" Enable NERDCommenterToggle to check all selected lines is commented or not
let g:NERDToggleCheckAllLines = 1

" linter
" w0rp has renamed himself to dense-analysis
Plug 'dense-analysis/ale'
Plug 'vim-syntastic/syntastic'

set rtp+=/usr/local/opt/fzf
Plug 'junegunn/fzf'
Plug 'junegunn/fzf.vim'
nnoremap <silent> ; :FZF<CR>
nnoremap <silent> ' :Rg<CR>

Plug 'yggdroot/indentline'
let g:indentLine_setConceal = 0

Plug 'vim-airline/vim-airline'
let g:airline#extensions#tabline#enabled = 1
" TODO: figure out how to show buffer number in tabline
" go to https://github.com/vim-airline/vim-airline#smarter-tab-line for all formatters
let g:airline#extensions#tabline#formatter = 'unique_tail'
let g:airline_powerline_fonts = 1

Plug 'mhinz/vim-startify'

" python
" Plug 'tmhedberg/simpylfold'
Plug 'nvie/vim-flake8'
Plug 'vim-scripts/indentpython.vim'
if has('python3')
  Plug 'sirver/ultisnips'
endif

" ruby on rails
Plug 'vim-ruby/vim-ruby'
Plug 'tpope/vim-rails'
Plug 'tpope/vim-endwise'
Plug 'tpope/vim-cucumber'
Plug 'tpope/vim-rake'
Plug 'tpope/vim-bundler'

" javascript and ember.js
Plug 'pangloss/vim-javascript'
Plug 'mustache/vim-mustache-handlebars'
Plug 'elzr/vim-json'
let g:vim_json_conceal=0

" tmux
Plug 'tmux-plugins/vim-tmux'

" markdown
Plug 'suan/vim-instant-markdown', {'rtp': 'after'}
" Uncomment to override defaults:
" let g:instant_markdown_slow = 1
" let g:instant_markdown_autostart = 0
" let g:instant_markdown_open_to_the_world = 1
" let g:instant_markdown_allow_unsafe_content = 1
" let g:instant_markdown_allow_external_content = 0
" let g:instant_markdown_mathjax = 1
" let g:instant_markdown_logfile = '/tmp/instant_markdown.log'
" let g:instant_markdown_autoscroll = 0
" let g:instant_markdown_port = 8888
" let g:instant_markdown_python = 1

Plug 'https://github.com/adelarsq/vim-matchit'

call plug#end()