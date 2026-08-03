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

# Surround: add, change and delete delimiter pairs around a motion, a
# textobject or a Visual selection.
#
# Built on Vim's documented operator interface (:h map-operator, :h g@).
# The <expr> mapping only reads keys and returns 'g@' - changing text from
# an <expr> mapping is blocked by |textlock| - and the edit happens in the
# 'operatorfunc' callback. Vim records `g@{motion}` for redo, so `.`
# repeats the last surround with the same delimiter.
#
# Nothing is yanked or put: edits are setline() splices. That matters
# because 'clipboard' is "unnamed", so any register detour would push the
# intermediate text onto the macOS pasteboard.

# Delimiter -> [opening, closing]. An opening char also adds inner spaces,
# its closing counterpart does not:
#   <leader>ysiw(  ->  ( foo )
#   <leader>ysiw)  ->  (foo)
const SurroundPairs = {
    '(': ['(', ')'], ')': ['(', ')'],
    '[': ['[', ']'], ']': ['[', ']'],
    '{': ['{', '}'], '}': ['{', '}'],
    '<': ['<', '>'], '>': ['<', '>'],
}
const SurroundSpaced = ['(', '[', '{', '<']

# Handed to the operator callback; survives until the next surround
# mapping, which is what lets `.` reuse the delimiter without asking.
var Pending: dict<any> = {}

def Warn(msg: string)
    echohl WarningMsg
    echomsg 'surround: ' .. msg
    echohl None
enddef

# Read one delimiter key; empty string means aborted. getchar() is
# explicitly allowed in an <expr> mapping and consumes typeahead, so
# `<leader>ds"` typed in one burst works (:h map-expression).
def AskDelim(prompt: string): string
    echohl ModeMsg
    echo prompt
    echohl None
    const ch = getcharstr()
    echo ''
    return ch == "\<Esc>" ? '' : ch
enddef

def Pair(ch: string, spaced: bool = true): list<string>
    const pair = get(SurroundPairs, ch, [ch, ch])
    if spaced && index(SurroundSpaced, ch) >= 0
        return [pair[0] .. ' ', ' ' .. pair[1]]
    endif
    return pair
enddef

# Byte index just past the character at 1-based byte column `col`.
def ByteAfter(lnum: number, col: number): number
    return col - 1 + strlen(matchstr(getline(lnum), '.', col - 1))
enddef

# Replace `len` bytes at 0-based byte index `idx` on line `lnum`.
def Splice(lnum: number, idx: number, len: number, ins: string)
    const line = getline(lnum)
    setline(lnum, strpart(line, 0, idx) .. ins .. strpart(line, idx + len))
enddef

# Edit the closing site first so the opening edit cannot shift its index.
# The operator has already parked the cursor at the start of the range, so
# shifting it past the inserted opening delimiter leaves it on the first
# character of the wrapped text rather than on the delimiter itself.
def Rewrite(l1: number, i1: number, n1: number, open: string,
            l2: number, i2: number, n2: number, close: string)
    var pos = getcurpos()
    Splice(l2, i2, n2, close)
    Splice(l1, i1, n1, open)
    if pos[1] == l1 && pos[2] > i1
        pos[2] += strlen(open) - n1
    endif
    setpos('.', pos)
enddef

# [lnum, byte idx, lnum, byte idx past end] of the operated region.
def OpRange(type: string): list<number>
    const p1 = getpos("'[")
    const p2 = getpos("']")
    if type == 'line'
        # for a linewise motion the mark columns are meaningless: wrap from
        # the first non-blank of the first line to the end of the last one
        const indent = match(getline(p1[1]), '\S')
        return [p1[1], indent < 0 ? 0 : indent, p2[1], strlen(getline(p2[1]))]
    endif
    return [p1[1], p1[2] - 1, p2[1], ByteAfter(p2[1], p2[2])]
enddef

def AddSurround(type: string)
    if !Pending.repeat
        # the motion comes first, so the delimiter is asked for here; on `.`
        # the mapping does not run again and this block is skipped
        const ch = AskDelim('surround with: ')
        if empty(ch)
            return
        endif
        Pending.pair = Pair(ch)
        Pending.repeat = true
    endif
    var [l1, i1, l2, i2] = OpRange(type)
    Rewrite(l1, i1, 0, Pending.pair[0], l2, i2, 0, Pending.pair[1])
enddef

# The motion was `i{old}`, so the marks bound the inner text and the
# delimiters are the single characters just outside it.
def RewrapSurround()
    const p1 = getpos("'[")
    const p2 = getpos("']")
    const line1 = getline(p1[1])
    const line2 = getline(p2[1])
    const open_idx = p1[2] - 2
    const close_idx = ByteAfter(p2[1], p2[2])
    const old = Pair(Pending.old, false)
    if open_idx < 0
            || strpart(line1, open_idx, 1) != old[0]
            || strpart(line2, close_idx, 1) != old[1]
        Warn('no ' .. old[0] .. old[1] .. ' pair on this line')
        return
    endif
    # an opening char also strips the inner spaces it would have added
    var open_len = 1
    var close_len = 1
    var close_at = close_idx
    if index(SurroundSpaced, Pending.old) >= 0
        if strpart(line1, open_idx + 1, 1) == ' '
            open_len += 1
        endif
        if close_idx > 0 && strpart(line2, close_idx - 1, 1) == ' '
            close_at -= 1
            close_len += 1
        endif
    endif
    Rewrite(p1[1], open_idx, open_len, Pending.pair[0],
            p2[1], close_at, close_len, Pending.pair[1])
enddef

def g:SurroundOperator(type: string)
    if !has_key(Pending, 'kind')
        return
    endif
    if type == 'block'
        Warn('blockwise selection is not supported')
        return
    endif
    if Pending.kind == 'add'
        AddSurround(type)
    else
        RewrapSurround()
    endif
enddef

def g:SurroundAdd(): string
    Pending = {kind: 'add', repeat: false, pair: ['', '']}
    &operatorfunc = 'g:SurroundOperator'
    return 'g@'
enddef

def g:SurroundChange(): string
    const old = AskDelim('change surround: ')
    if empty(old)
        return ''
    endif
    const new_delim = AskDelim('change ' .. old .. ' to: ')
    if empty(new_delim)
        return ''
    endif
    Pending = {kind: 'rewrap', old: old, pair: Pair(new_delim)}
    &operatorfunc = 'g:SurroundOperator'
    return 'g@i' .. old
enddef

def g:SurroundDelete(): string
    const old = AskDelim('delete surround: ')
    if empty(old)
        return ''
    endif
    Pending = {kind: 'rewrap', old: old, pair: ['', '']}
    &operatorfunc = 'g:SurroundOperator'
    return 'g@i' .. old
enddef

# <leader>ys{motion}{delim}, <leader>yss{delim} for the whole line,
# <leader>s{delim} in Visual mode, <leader>cs{old}{new}, <leader>ds{old}
nnoremap <expr> <leader>ys  g:SurroundAdd()
nnoremap <expr> <leader>yss g:SurroundAdd() .. '_'
xnoremap <expr> <leader>s   g:SurroundAdd()
nnoremap <expr> <leader>cs  g:SurroundChange()
nnoremap <expr> <leader>ds  g:SurroundDelete()
