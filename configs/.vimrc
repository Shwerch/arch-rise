nnoremap <C-b> :NERDTreeToggle<CR>

nnoremap <C-y> "+y
vnoremap <C-y> "+y

set langmap=ФИСВУАПРШОЛДЬТЩЗЙКЫЕГМЦЧНЯ;ABCDEFGHIJKLMNOPQRSTUVWXYZ,фисвуапршолдьтщзйкыегмцчня;abcdefghijklmnopqrstuvwxyz

nnoremap <Esc> :nohlsearch<CR>

nnoremap <C-D> <C-D>zz
nnoremap <C-U> <C-U>zz

set encoding=utf-8
set fileencodings=utf-8

set hlsearch
set incsearch
set ic
set smartcase

set expandtab
set tabstop=4
set shiftwidth=4
set softtabstop=4

set nocompatible

" set relativenumber
set number
set numberwidth=1

syntax on
highlight LineNr ctermfg=NONE guifg=NONE
highlight CursorLineNr ctermfg=NONE guifg=NONE
set modelines=0

set scrolloff=5
set background=dark

set smarttab
set smartindent

set backspace=indent,eol,start
set nowrap
set ruler
set mouse=a