set nocompatible

if empty(glob('~/.vim/autoload/plug.vim'))
  silent !curl -fLo ~/.vim/autoload/plug.vim --create-dirs
      \ https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
    autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

call plug#begin(expand('~/.vim/plugged'))
" Color Schemes
Plug 'catppuccin/vim', { 'as': 'catppuccin' }

" Color Preview
Plug 'rrethy/vim-hexokinase', { 'do': 'make hexokinase' }

" Other
Plug 'fatih/vim-go', { 'do': ':GoUpdateBinaries' }
Plug 'vim-airline/vim-airline'
Plug 'tpope/vim-fugitive'
Plug 'preservim/nerdtree'
Plug 'neoclide/coc.nvim', { 'branch': 'release' }
Plug 'chase/vim-ansible-yaml'
Plug 'godlygeek/tabular'
Plug 'mhinz/vim-signify'
Plug 'rhysd/git-messenger.vim'
Plug 'ctrlpvim/ctrlp.vim'
Plug 'pangloss/vim-javascript'
Plug 'leafgarland/typescript-vim'
Plug 'maxmellon/vim-jsx-pretty'
Plug 'vimwiki/vimwiki'
Plug 'iamcco/markdown-preview.nvim', { 'do': { -> mkdp#util#install() }, 'for': ['markdown', 'vim-plug']}
Plug 'pedrohdz/vim-yaml-folds'
Plug 'sheerun/vim-polyglot'
call plug#end()

set showcmd
let mapleader = ","

syntax on

" #############
" Color Scheme
" #############
silent! colorscheme catppuccin_mocha
" OVERRIDE: Make the background trasparent
hi Normal guibg=NONE ctermbg=NONE
hi SignColumn guifg=NONE guibg=NONE ctermbg=NONE

if (has("termguicolors"))
  set termguicolors
endif

:autocmd InsertEnter,InsertLeave * set cul!

let g:lightline = { 'colorscheme': 'catppuccin_mocha' }

let g:palenight_terminal_italics=1
let g:embark_terminal_italics = 1

" Change comment color
highlight Comment ctermfg=245
highlight Identifir ctermfg=150

" #############
" Hexokinase
" #############
let g:Hexokinase_highlighters = ['sign_column']
let g:Hexokinase_optInPatterns = 'full_hex,rgb,rgba,hsl,hsla'

" #############
" CtrlP
" #############
let g:ctrlp_map = '<c-p>'
let g:ctrlp_cmd = 'CtrlP'
let g:ctrlp_working_path_mode = ''
let g:ctrlp_max_files=20000
let g:ctrlp_max_depth=40

" #############
" Indentline Settings
" #############
let g:vim_json_conceal=1
let g:markdown_syntax_conceal=1

" #############
" CoC
" #############
set updatetime=300
set signcolumn=yes

let g:coc_global_extensions = ['coc-tsserver', 'coc-yaml', 'coc-go', 'coc-rust-analyzer']

" Remap keys for applying codeAction to the current line.
nmap <leader>ac  <Plug>(coc-codeaction)

" Apply AutoFix to problem on the current line.
nmap <leader>qf  <Plug>(coc-fix-current)

" Use `[g` and `]g` to navigate diagnostics
" Use `:CocDiagnostics` to get all diagnostics of current buffer in location list.
nmap <silent> [g <Plug>(coc-diagnostic-prev)
nmap <silent> ]g <Plug>(coc-diagnostic-next)

" GoTo code navigation.
nmap <silent> gd <Plug>(coc-definition)
nmap <silent> gy <Plug>(coc-type-definition)
nmap <silent> gi <Plug>(coc-implementation)
nmap <silent> gr <Plug>(coc-references)

" use <tab> for trigger completion and navigate to the next complete item
inoremap <silent><expr> <Tab>
      \ coc#pum#visible() ? coc#pum#next(1) :
      \ CheckBackspace() ? "\<Tab>" :
      \ coc#refresh()

" Use <cr> to confirm completion
inoremap <silent><expr> <CR> coc#pum#visible() ? coc#pum#confirm()
                              \: "\<C-g>u\<CR>\<c-r>=coc#on_enter()\<CR>"

" Use K to show documentation in preview window.
nnoremap <silent> K :call ShowDocumentation()<CR>

" use <c-space>for trigger completion
if has('nvim')
  inoremap <silent><expr> <c-space> coc#refresh()
else
  inoremap <silent><expr> <c-@> coc#refresh()
endif

inoremap <expr> <Tab> coc#pum#visible() ? coc#pum#next(1) : "\<Tab>"
inoremap <expr> <S-Tab> coc#pum#visible() ? coc#pum#prev(1) : "\<S-Tab>"

" Highlight the symbol and its references when holding the cursor.
autocmd CursorHold * silent call CocActionAsync('highlight')

" Symbol renaming.
nmap <leader>n <Plug>(coc-rename)

" Run the Code Lens action on the current line.
nmap <leader>cl  <Plug>(coc-codelens-action)

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
" 
" #############
let g:python3_host_prog='/usr/bin/python3'

" Enable line numbers
set number

" Flash screen instead of beep sound
set visualbell

" Change how vim represents characters on the screen
set encoding=utf-8

" Set the encoding of files written
set fileencoding=utf-8

autocmd FileType yaml setlocal ts=2 sts=2 sw=2 expandtab
set ts=4 sw=4 sts=4 expandtab
" ts - show existing tab with 4 spaces width
" sw - when indenting with '>', use 4 spaces width
" sts - control <tab> and <bs> keys to match tabstop

let g:indentLine_char = '⦙'
set foldlevelstart=20

set undofile " Maintain undo history between sessions
set undodir=~/.vim/undodir

" Hardcore mode, disable arrow keys.
"noremap <Up> <NOP>
"noremap <Down> <NOP>
"noremap <Left> <NOP>
"noremap <Right> <NOP>

filetype plugin indent on

" Allow backspace to delete indentation and inserted text
" i.e. how it works in most programs
set backspace=indent,eol,start
" indent  allow backspacing over autoindent
" eol     allow backspacing over line breaks (join lines)
" start   allow backspacing over the start of insert; CTRL-W and CTRL-U
"        stop once at the start of insert.


" go-vim plugin specific commands
" Also run `goimports` on your current file on every save
" Might be be slow on large codebases, if so, just comment it out
let g:go_fmt_command = "goimports"

" Status line types/signatures.
let g:go_auto_type_info = 1

let g:nord_cursor_line_number_background = 1

"au filetype go inoremap <buffer> . .<C-x><C-o>

" If you want to disable gofmt on save
" let g:go_fmt_autosave = 0


" NERDTree plugin specific commands
:nnoremap <C-g> :NERDTreeToggle<CR>
" autocmd vimenter * NERDTree


" air-line plugin specific commands
let g:airline_powerline_fonts = 1

if !exists('g:airline_symbols')
    let g:airline_symbols = {}
endif

" unicode symbols
let g:airline_left_sep = '»'
let g:airline_left_sep = '▶'
let g:airline_right_sep = '«'
let g:airline_right_sep = '◀'
let g:airline_symbols.linenr = '␊'
let g:airline_symbols.linenr = '␤'
let g:airline_symbols.linenr = '¶'
let g:airline_symbols.branch = '⎇'
let g:airline_symbols.paste = 'ρ'
let g:airline_symbols.paste = 'Þ'
let g:airline_symbols.paste = '∥'
let g:airline_symbols.whitespace = 'Ξ'

" airline symbols
let g:airline_left_sep = ''
let g:airline_left_alt_sep = ''
let g:airline_right_sep = ''
let g:airline_right_alt_sep = ''
let g:airline_symbols.branch = ''
let g:airline_symbols.readonly = ''
let g:airline_symbols.linenr = ''

" ale
"let g:ale_fixers = {
"    \ 'javascript': ['eslint']
"    \}
"
"nmap <leader>d <Plug>(ale_fix)
"let g:ale_fix_on_save = 1
"let g:ale_sign_error = '×'
"let g:ale_sign_warning = '⚠'
"highlight ALEErrorSign ctermbg=NONE ctermfg=red
"highlight ALEWarningSign ctermbg=NONE ctermfg=yellow

"au filetype go inoremap <buffer> . .<C-x><C-o>

set autowrite

" Go syntax highlighting
let g:go_highlight_types = 1
let g:go_highlight_fields = 1
let g:go_highlight_functions = 1
let g:go_highlight_function_calls = 1
let g:go_highlight_operators = 1
let g:go_highlight_extra_types = 1
let g:go_highlight_build_constraints = 1
let g:go_highlight_generate_tags = 1

" Auto formatting and importing
let g:go_fmt_autosave = 1
let g:go_fmt_command = "goimports"

" Status line types/signatures
let g:go_auto_type_info = 1

" Disable vim-go autocompletion in favor of CoC
let g:go_code_completion_enabled = 0

" disable all linters as that is taken care of by coc.nvim
let g:go_diagnostics_enabled = 0
let g:go_metalinter_enabled = []

autocmd FileType go nmap <leader>b :<C-u>call <SID>build_go_files()<CR>
autocmd FileType go nmap <leader>r  <Plug>(go-run)
autocmd FileType go nmap <leader>l  <Plug>(go-test)

let g:NERDTreeDirArrowExpandable = '▸'
let g:NERDTreeDirArrowCollapsible = '▾'
let NERDTreeShowHidden=1

" Custom function to remove Alacritty padding when using VIM
"function RemoveAlacrittyPadding()
"    silent !sed -i '37s/15/0/' ~/.config/alacritty/alacritty.yml
"    silent !sed -i '38s/20/0/' ~/.config/alacritty/alacritty.yml
"endfunction
"
"function AddAlacrittyPadding()
"    silent !sed -i '37s/0/15/' ~/.config/alacritty/alacritty.yml
"    silent !sed -i '38s/0/20/' ~/.config/alacritty/alacritty.yml
"endfunction
"
"autocmd VimEnter * call RemoveAlacrittyPadding()
"autocmd VimLeavePre * call AddAlacrittyPadding()

" vim hardcodes background color erase even if the terminfo file does
" not contain bce (not to mention that libvte based terminals
" incorrectly contain bce in their terminfo files). This causes
" incorrect background rendering when using a color theme with a
" background color.
let &t_ut=''

" Set effect of visual bell to nothing
set t_vb=
