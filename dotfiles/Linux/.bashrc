# .bashrc

# Source global definitions
if [ -f /etc/bashrc ]; then
	. /etc/bashrc
fi

# User specific environment
if ! [[ "$PATH" =~ "$HOME/.local/bin:$HOME/bin:" ]]
then
    PATH="$HOME/.local/bin:$HOME/bin:$PATH"
fi
export PATH

# Uncomment the following line if you don't like systemctl's auto-paging feature:
# export SYSTEMD_PAGER=

# User specific aliases and functions
if [ -d ~/.bashrc.d ]; then
	for rc in ~/.bashrc.d/*; do
		if [ -f "$rc" ]; then
			. "$rc"
		fi
	done
fi

unset rc
. "$HOME/.cargo/env"

#========================================================
#                        COMPLETION 
#========================================================

#========================================================
#                        EXPORT
#========================================================
# setting PATH for user local bin folders
PATH="${HOME}/.local/bin:${HOME}/bin:/usr/local/sbin:${PATH}"

# the cargo's (rust package manager) bin dir
PATH="${HOME}/.cargo/bin:${PATH}"

export PATH
export EDITOR=vim
#========================================================
#                       ALIASES
#========================================================
alias lsofc='lsof -i |grep -Ei "(listen|established)"'
alias gpg='gpg --pinentry-mode=loopback --quiet'
alias swp="bash ${HOME}/utils/search-replace.sh"
alias fr="bash ${HOME}/obs/repos/github.com/enkron/utils/dotfiles_rotation.sh"

#========================================================
#                       MISC
#========================================================
umask 0077

#========================================================
#                     FUNCTIONS 
#========================================================

#========================================================
#                       PROMT 
#========================================================
export PS1="\e[1;30m$SHLVL:$(echo $(tty) |awk -F '/' '{ print $4 }')>\e[m "
