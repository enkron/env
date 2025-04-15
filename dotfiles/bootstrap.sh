#!/bin/sh

install_nix() {
    curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix |\
        sh -s -- install --determinate --no-confirm
}

if [ $(uname -s) = 'Darwin' ]; then
    # Add link to the Icloud storage on the filesystem
	ln -s ~/Library/Mobile\ Documents/com~apple~CloudDocs ~/icloud

    # Disable MacOS press and hold feature in the Cursor app to allow
    # continuous key movement in Vim mode
    if [ -x $(which cursor) ]; then
        defaults write $(osascript -e 'id of app "Cursor"') ApplePressAndHoldEnabled -bool false
    fi
fi

mkdir -p ~/rps/github.com
git clone git@github.com:enkron/env.git ~/rps/github.com/env

ln -s ~/rps/github.com/env/dotfiles/Linux/gitconfig ~/.gitconfig
ln -s ~/rps/github.com/env/dotfiles/Linux/vimrc ~/.vimrc

git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim

install_nix
