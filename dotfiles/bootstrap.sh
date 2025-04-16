#!/bin/sh

REPOS_HOME="${HOME}/rps/github.com"

install_nix() {
    curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | \
        sh -s -- install --determinate --no-confirm
}

if [ -d "${REPOS_HOME}/env" ]; then
    echo "env repository already exists, skipping clone step"
else
    git clone git@github.com:enkron/env.git "${REPOS_HOME}/env"
fi

if [ "$(uname -s)" = 'Darwin' ]; then
    # Add link to the Icloud storage on the filesystem
    ln -sf "${HOME}/Library/Mobile Documents/com~apple~CloudDocs" "${HOME}/icloud"

    # Disable MacOS press and hold feature in the Cursor app to allow
    # continuous key movement in Vim mode
    if command -v cursor >/dev/null 2>&1; then
        cursor_config_path="${HOME}/Library/Application Support/Cursor/User"

        defaults write "$(osascript -e 'id of app "Cursor"')" ApplePressAndHoldEnabled -bool false
        ln -sf "${REPOS_HOME}/env/dotfiles/cursor/keybindings.json" "${cursor_config_path}/keybindings.json"
        ln -sf "${REPOS_HOME}/env/dotfiles/cursor/settings.json" "${cursor_config_path}/settings.json"
    fi
fi

ln -sf "${REPOS_HOME}/env/dotfiles/gitconfig" "${HOME}/.gitconfig"
ln -sf "${REPOS_HOME}/env/dotfiles/vimrc" "${HOME}/.vimrc"

if [ -d "${HOME}/.vim/bundle/Vundle.vim" ]; then
    echo "Vundle.vim already exists, skipping clone step"
else
    git clone https://github.com/VundleVim/Vundle.vim.git "${HOME}/.vim/bundle/Vundle.vim"
fi

if command -v nix >/dev/null 2>&1; then
    echo "nix already installed, skipping installation step"
else
    install_nix
fi
