#!/bin/sh

install_nix() {
    curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | \
        sh -s -- install --determinate --no-confirm
}

if [ "$(uname -s)" = 'Darwin' ]; then
    # Add link to the Icloud storage on the filesystem
    ln -s "${HOME}/Library/Mobile Documents/com~apple~CloudDocs" "${HOME}/icloud"

    # Disable MacOS press and hold feature in the Cursor app to allow
    # continuous key movement in Vim mode
    if command -v cursor >/dev/null 2>&1; then
        defaults write "$(osascript -e 'id of app "Cursor"')" ApplePressAndHoldEnabled -bool false
    fi
fi

mkdir -p "${HOME}/rps/github.com"
git clone git@github.com:enkron/env.git "${HOME}/rps/github.com/env"

ln -s "${HOME}/rps/github.com/env/dotfiles/Linux/gitconfig" "${HOME}/.gitconfig"
ln -s "${HOME}/rps/github.com/env/dotfiles/Linux/vimrc" "${HOME}/.vimrc"

git clone https://github.com/VundleVim/Vundle.vim.git "${HOME}/.vim/bundle/Vundle.vim"

install_nix
