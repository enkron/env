vim9script

set laststatus=2                        # show the status on the second to last line
set statusline=                         # clear status line when vimrc is reloaded
set statusline+=%1*\%{&ff}%y\ %*
set statusline+=%2*\»\ %*
set statusline+=%3*\%n%m\%*
set statusline+=%1*\:%t\ %*
set statusline+=%=
set statusline+=%5*\%4l%*
set statusline+=%6*/%*
set statusline+=%1*\%L%*
set statusline+=%2*\ «\ %*
set statusline+=%4*\0x%B\%*
set statusline+=%6*/%*
set statusline+=%5*%c\%*
# set statusline=%<%F%=\ [%1*%M%*%n%R%H]\ %-19(%3l.%02c%03V%)%-6(%p%%%)%O'%02b'
