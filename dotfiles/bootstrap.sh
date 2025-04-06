#!/bin/sh


install_nix() {
    curl --proto =https --tlsv1.2 -sSf -L https://install.determinate.systems/nix |\
        sh -s -- install --no-confirm
}

if [ $(uname -s) = 'Darwin' ]; then
	ln -s ~/Library/Mobile\ Documents/com~apple~CloudDocs ~/icloud
fi

mkdir -p ~/rps/github.com
git clone git@github.com:enkron/env.git ~/rps/github.com/env

ln -s ~/rps/github.com/env/dotfiles/Linux/gitconfig ~/.gitconfig
ln -s ~/rps/github.com/env/dotfiles/Linux/vimrc ~/.vimrc

git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim

install_nix
