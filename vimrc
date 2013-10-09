set mouse=a
set clipboard=unnamed

set nobackup
set nowritebackup
set noswapfile

set nocompatible
set backspace=2
set nohlsearch
set number
set magic
set splitbelow
set whichwrap=<,>,h,l,[,] 

set hidden

set tabstop=4 "set tab character to 4 characters
set expandtab "turn tabs into whitespace
set shiftwidth=4 "indent width for autoindent

if has("autocmd")
    filetype plugin on
    filetype plugin indent on "indent depends on filetype
    autocmd FileType text setlocal textwidth=78
endif

syntax enable

set incsearch
set ignorecase
set smartcase

set statusline=%F%m%r%h%w\ [TYPE=%Y\ %{&ff}]\ [%l/%L\ (%p%%)]
syntax enable

"Hide buffer when not in window (to prevent relogin with FTP edit)
set bufhidden=hide
set scrolloff=3
set guitablabel=%M\ %f

colorscheme slate

set titlestring=vim\ %<%F%(\ %)%m%h%w%=%l/%L-%P 
set titlelen=70

if $TERM=='screen'
    exe "set title titlestring=vim:%f"
    exe "set title t_ts=\<ESC>k t_fs=\<ESC>\\"
endif

nnoremap <C-N><C-N> :set invnumber<CR>
nnoremap <C-w><C-w> :set invwrap<CR>
