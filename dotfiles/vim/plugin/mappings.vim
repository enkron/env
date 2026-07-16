vim9script

# Below function allows to avoid entering the `INSERT` mode while splitting a
# long line (Vim doesn't have this type of method by default)
def g:SplitLine()
    s/^\(\s*\)\(.\{-}\)\(\s*\)\(\%#\)\(\s*\)\(.*\)/\1\2\r\1\4\6
    histdel('/', -1)
enddef

def g:ScrollPopup(nlines: number)
    var winids = popup_list()
    if len(winids) == 0
        return
    endif

    var prop = popup_getpos(winids[0])
    if prop.visible != 1
        return
    endif

    var firstline = prop.firstline + nlines
    var buf_lastline = str2nr(trim(win_execute(winids[0], "echo line('$')")))
    if firstline < 1
        firstline = 1
    elseif prop.lastline + nlines > buf_lastline
        firstline = buf_lastline + prop.firstline - prop.lastline
    endif

    popup_setoptions(winids[0], {'firstline': firstline})
enddef

# nnoremap - allows to map keys in normal mode
# inoremap - allows to map keys in insert mode
# vnoremap - allows to map keys in visual mode
# g:mapleader is set in the vimrc (it must be defined before this file
# is sourced)

# the more often save action occurs, the more likely the data won't be
# lost
# nnoremap <Space> :w!<CR>
# rewrites the command line right before execution instead of intercepting
# the submit keystroke, so it isn't affected by terminals/multiplexers that
# report Ctrl-M as a Kitty-protocol-disambiguated event rather than a plain
# CR byte (breaks a cnoremap keyed on <C-m>/<CR>)
augroup FixTypedSaveCommand
    autocmd!
    autocmd CmdlineLeavePre : if getcmdline() == 'W' | call setcmdline('w!') | endif
augroup END

# switch between buffers
nnoremap <leader>b :ls<CR>:buffer<Space>
# switch between last buffers
nnoremap <leader>ll :b#<CR>

# ugly change pattern
nnoremap <leader>c :%s///g<Left><Left><Left>
# replace all occurences of a particular word under the cursor
nnoremap <leader>co :%s/\<<C-r>=expand('<cword>')<CR>\>//g<Left><Left>
# replace all occurences of a word on a current row only
nnoremap <leader>cl :.s/\<<C-r>=expand('<cword>')<CR>\>//g<Left><Left>
# count number of matches of a pattern
nnoremap <leader>gn :%s/\<<C-r>=expand('<cword>')<CR>\>//gn<CR>

# release search highlighting
nnoremap <leader><space> :nohlsearch<CR>

# switch between bracets pairs (actual for mac keyboard)
nnoremap ~ %

# on/off trailing whitespace visibility (indent guides stay on)
nnoremap <leader>l :set listchars+=trail:∙,eol:¶<CR>
nnoremap <leader>nl :set listchars-=trail:∙ listchars-=eol:¶<CR>

# obtain highlighting information under the coursor
nnoremap <leader>hi :execute 'hi' synIDattr(synID(line("."), col("."), 1), "name")<CR>

# change behaviour of the `o` and `O` keys: by default these keys enters
# into the INSERT mode immediately after a call, below binding leaves it
# in COMMAND mode
nnoremap o o<ESC>
nnoremap <S-o> <S-o><ESC>

# format all long lines in a file without affecting short lines
# tw (textwidth) option could be set for a new formatting option
# check existing tw -> :setl tw?
# reset current tw to defaults -> :setl tw&
nmap <leader>f :g/./ normal gqq<CR><ESC> :nohlsearch<CR>``

# most of the Linux terminals sends the escape by default when pressing
# alt/meta+normal_mode_key
imap <M-h> <ESC>

# map Left to Ctrl+b in cmd mode to have behaviour like in terminal
cnoremap <C-b> <Left>
# map Right to Ctrl+f in cmd mode to have behaviour like in terminal
cnoremap <C-f> <Right>
# map Home to Ctrl+a in cmd mode to have behaviour like in terminal
cnoremap <C-a> <Home>

# inoremap () ()<Left>
# inoremap [] []<Left>
# inoremap {} {}<Left>
# inoremap "" ""<Left>
# inoremap ' ''<Left>
# inoremap ` ``<Left>

# search mappings: these will make it so that going to the
# next one in a search will center on the line it's found in.
nnoremap n nzzzv
nnoremap N Nzzzv

# when long lines inserted j k moves one physical line
# gj gk moves down one displayed line
noremap <Up> gk
noremap <Down> gj
noremap j gj
noremap k gk

# maybe later i'll figure out for what this mode is needed..
nnoremap Q <NOP>
# do not show q: window
# upd(24-Mar-22): understood at last: q: - shows the history of last
# commands, also 'q:' suffix works within gq+(line_num/G) command
# eg. `gq3<CR>` - formats next 3 lines according to the `tw` value
# nnoremap q: <NOP>

# reload vim configuration file
# nnoremap <leader>rc :source<space>~/.vimrc<CR>

# split long lines in `NORMAL` mode
nnoremap <leader>sl :<C-u>call SplitLine()<CR>

# add a `?` to the end of the line,
# return the cursor to its original spot.
inoremap ?? <C-o>mp<C-o>A?<C-o>`p

# sync syntax highlighting (sometimes vim gets confused in a long file)
nnoremap <leader>ss :syntax sync fromstart<CR>

# popup window scrolling
nnoremap <C-n> <Cmd>call g:ScrollPopup(3)<CR>
nnoremap <C-p> <Cmd>call g:ScrollPopup(-3)<CR>

# Restore "drag to select, release to copy" feel now that Vim owns the
# mouse: yank the just-made visual selection straight to the system
# clipboard when the drag ends. Only fires from an active Visual selection
# (started by the drag itself), so plain clicks are unaffected.
vnoremap <LeftRelease> <LeftRelease>"+y

# Reload undo history
nmap <leader>ee :setl undoreload=0 \|edit<CR>

# Source ~/.vimrc
nmap <leader>rc :source $MYVIMRC<CR>:nohlsearch<CR>

# Fix nearest misspelling and return to cursor position
inoremap <C-l> <C-g>u<Esc>[s1z=`]a<C-g>u

# LSP key mappings
# Basic IDE-style navigation using yegappan/lsp

# Go to definition
nnoremap <leader>gt :LspGotoDefinition<CR>
# Find references
nnoremap <leader>gr :LspShowReferences<CR>
# Go to implementation
nnoremap <leader>gi :LspGotoImpl<CR>
# Rename symbol
nnoremap <leader>rn :LspRename<CR>
# Show documentation
nnoremap <leader>p  :LspHover<CR>
# Symbols in file
nnoremap <leader>fs :LspDocumentSymbol<CR>
# Workspace symbols
nnoremap <leader>ws :LspSymbolSearch<CR>
# Code actions (fix, refactor)
nnoremap <leader>ca :LspCodeAction<CR>
# Go to declaration
nnoremap <leader>gd :LspGotoDeclaration<CR>
# Next error
nnoremap <leader>e  :LspDiag next<CR>
# Previous error
nnoremap <leader>E  :LspDiag prev<CR>
