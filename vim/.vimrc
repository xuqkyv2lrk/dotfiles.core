set nocompatible

if empty(glob('~/.vim/autoload/plug.vim'))
  silent !curl -fLo ~/.vim/autoload/plug.vim --create-dirs
      \ https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
endif

if empty(glob('~/.vim/plugged'))
  autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

call plug#begin(expand('~/.vim/plugged'))

" Color scheme
Plug 'catppuccin/vim', { 'as': 'catppuccin' }

" Color preview
Plug 'rrethy/vim-hexokinase', { 'do': 'make hexokinase' }

" Language support
Plug 'fatih/vim-go', { 'do': ':GoInstallBinaries' }
Plug 'rust-lang/rust.vim'
Plug 'timonv/vim-cargo'
Plug 'pangloss/vim-javascript'
Plug 'leafgarland/typescript-vim'
Plug 'maxmellon/vim-jsx-pretty'
Plug 'chase/vim-ansible-yaml'
Plug 'pedrohdz/vim-yaml-folds'
Plug 'sheerun/vim-polyglot'

" LSP / completion
Plug 'neoclide/coc.nvim', { 'branch': 'release' }

" UI
Plug 'vim-airline/vim-airline'
Plug 'tpope/vim-vinegar'
Plug 'mhinz/vim-signify'
Plug 'rhysd/git-messenger.vim'
Plug 'ctrlpvim/ctrlp.vim'

" Git
Plug 'tpope/vim-fugitive'

" Editing
Plug 'godlygeek/tabular'

" Notes / Markdown
Plug 'vimwiki/vimwiki'
Plug 'iamcco/markdown-preview.nvim', { 'do': { -> mkdp#util#install() }, 'for': ['markdown', 'vim-plug']}

call plug#end()

filetype plugin indent on
syntax on

" #############
" General
" #############
set showcmd
set number
set encoding=utf-8
set fileencoding=utf-8
set visualbell
set t_vb=
set backspace=indent,eol,start
set updatetime=300
set signcolumn=yes
set autowrite
set undofile
set undodir=~/.vim/undodir
set foldlevelstart=20
set hlsearch

let mapleader = ","

nnoremap <silent> <CR> :nohlsearch<CR><CR>

autocmd InsertEnter,InsertLeave * set cul!

" #############
" Color Scheme
" #############
if has("termguicolors")
  set termguicolors
endif

silent! colorscheme catppuccin_mocha

hi Normal     guibg=NONE ctermbg=NONE
hi SignColumn guifg=NONE guibg=NONE ctermbg=NONE

highlight Comment    ctermfg=245
highlight Identifier ctermfg=150

" #############
" Indentation
" #############
set ts=4 sw=4 sts=4 expandtab

autocmd FileType yaml setlocal ts=2 sts=2 sw=2 expandtab
autocmd FileType rust setlocal ts=4 sts=4 sw=4 expandtab

" #############
" JSON / Markdown
" #############
let g:vim_json_conceal        = 1
let g:markdown_syntax_conceal = 1

" #############
" Hexokinase
" #############
let g:Hexokinase_highlighters  = ['sign_column']
let g:Hexokinase_optInPatterns = 'full_hex,rgb,rgba,hsl,hsla'

" #############
" CtrlP
" #############
let g:ctrlp_map               = '<c-p>'
let g:ctrlp_cmd               = 'CtrlP'
let g:ctrlp_working_path_mode = ''
let g:ctrlp_max_files         = 20000
let g:ctrlp_max_depth         = 40

" #############
" Signify
" #############
" Lower priority so CoC diagnostic signs take precedence on the same line
let g:signify_priority = 5

" #############
" Airline
" #############
let g:airline_powerline_fonts = 1

if !exists('g:airline_symbols')
  let g:airline_symbols = {}
endif

let g:airline_left_sep         = ''
let g:airline_left_alt_sep     = ''
let g:airline_right_sep        = ''
let g:airline_right_alt_sep    = ''
let g:airline_symbols.branch   = ''
let g:airline_symbols.readonly = ''
let g:airline_symbols.linenr   = ''

" #############
" CoC
" #############
let g:coc_global_extensions = ['coc-tsserver', 'coc-yaml', 'coc-rust-analyzer', 'coc-sh']

" Diagnostics navigation
nmap <silent> [g <Plug>(coc-diagnostic-prev)
nmap <silent> ]g <Plug>(coc-diagnostic-next)

" Diagnostics float window
nmap <silent> <leader>ce :call CocActionAsync('diagnosticInfo')<CR>

" Code navigation
nmap <silent> gd <Plug>(coc-definition)
nmap <silent> gy <Plug>(coc-type-definition)
nmap <silent> gi <Plug>(coc-implementation)
nmap <silent> gr <Plug>(coc-references)

" Code actions
nmap <leader>ac <Plug>(coc-codeaction)
nmap <leader>qf <Plug>(coc-fix-current)
nmap <leader>n  <Plug>(coc-rename)
nmap <leader>cl <Plug>(coc-codelens-action)

" Organize imports
nmap <silent> <leader>oi :call CocActionAsync('runCommand', 'editor.action.organizeImport')<CR>

" Hover documentation
nnoremap <silent> K :call ShowDocumentation()<CR>

" Tab: navigate completion or insert literal tab
inoremap <silent><expr> <Tab>
      \ coc#pum#visible() ? coc#pum#next(1) :
      \ CheckBackspace() ? "\<Tab>" :
      \ coc#refresh()
inoremap <expr> <S-Tab> coc#pum#visible() ? coc#pum#prev(1) : "\<S-Tab>"

" Enter: confirm completion or insert newline
inoremap <silent><expr> <CR> coc#pum#visible() ? coc#pum#confirm()
                              \: "\<C-g>u\<CR>\<c-r>=coc#on_enter()\<CR>"

" Manually trigger completion
if has('nvim')
  inoremap <silent><expr> <c-space> coc#refresh()
else
  inoremap <silent><expr> <c-@> coc#refresh()
endif

" Highlight symbol and references on cursor hold
autocmd CursorHold * silent call CocActionAsync('highlight')

function! CheckBackspace() abort
  let col = col('.') - 1
  return !col || getline('.')[col - 1]  =~# '\s'
endfunction

function! ShowDocumentation()
  if CocAction('hasProvider', 'hover')
    call CocActionAsync('doHover')
  else
    call feedkeys('K', 'in')
  endif
endfunction

" #############
" Go
" #############
let g:go_highlight_types             = 1
let g:go_highlight_fields            = 1
let g:go_highlight_functions         = 1
let g:go_highlight_function_calls    = 1
let g:go_highlight_operators         = 1
let g:go_highlight_extra_types       = 1
let g:go_highlight_build_constraints = 1
let g:go_highlight_generate_tags     = 1

let g:go_fmt_autosave            = 1
let g:go_fmt_command             = "goimports"
let g:go_auto_type_info          = 1
let g:go_code_completion_enabled = 0
let g:go_diagnostics_enabled     = 0
let g:go_metalinter_enabled      = []

function! s:build_go_files()
  let l:file = expand('%')
  if l:file =~# '^\f\+_test\.go$'
    call go#test#Test(0, 1)
  else
    call go#cmd#Build(0)
  endif
endfunction

augroup go_commands
  autocmd!
  autocmd FileType go nmap <buffer> <leader>b :<C-u>call <SID>build_go_files()<CR>
  autocmd FileType go nmap <buffer> <leader>r <Plug>(go-run)
  autocmd FileType go nmap <buffer> <leader>l <Plug>(go-test)
augroup END

" #############
" Rust
" #############
let g:rustfmt_autosave = 1

augroup rust_commands
  autocmd!
  autocmd FileType rust nmap <buffer> <leader>rb :CargoBuild<CR>
  autocmd FileType rust nmap <buffer> <leader>rt :CargoTest<CR>
  autocmd FileType rust nmap <buffer> <leader>rr :CargoRun<CR>
  autocmd FileType rust nmap <buffer> <leader>rc :CargoCheck<CR>
augroup END

" #############
" Terminal
" #############
" Prevent terminal emulators from erasing background with background color
let &t_ut=''
