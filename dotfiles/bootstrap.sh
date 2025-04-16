#!/bin/sh

REPOS_HOME="${HOME}/rps/github.com"

log() {
    case "$1" in
        info)
            echo "\033[1;32m[INFO]\033[0m $2"
            ;;
        warning)
            echo "\033[1;33m[WARNING]\033[0m $2"
            ;;
        error)
            echo "\033[1;31m[ERROR]\033[0m $2"
            ;;
        *)
            echo "\033[1;37m[LOG]\033[0m $2"
            ;;
    esac
}

install_nix() {
    curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | \
        sh -s -- install --determinate --no-confirm
}

if [ -d "${REPOS_HOME}/env" ]; then
    log warning "env repository already exists, skipping clone step"
else
    log info "Cloning env repository"
    git clone git@github.com:enkron/env.git "${REPOS_HOME}/env"
fi

if [ "$(uname -s)" = 'Darwin' ]; then
    # Add link to the Icloud storage on the filesystem
    log info "Adding link to the Icloud storage on the filesystem"
    ln -sf "${HOME}/Library/Mobile Documents/com~apple~CloudDocs" "${HOME}/icloud"

    # Disable MacOS press and hold feature in the Cursor app to allow
    # continuous key movement in Vim mode
    if command -v cursor >/dev/null 2>&1; then
        cursor_config_path="${HOME}/Library/Application Support/Cursor/User"

        log info "Disabling MacOS press and hold feature in the Cursor app"
        defaults write "$(osascript -e 'id of app "Cursor"')" ApplePressAndHoldEnabled -bool false

        log info "Linking Cursor keybindings"
        ln -sf "${REPOS_HOME}/env/dotfiles/cursor/keybindings.json" "${cursor_config_path}/keybindings.json"

        log info "Linking Cursor settings"
        ln -sf "${REPOS_HOME}/env/dotfiles/cursor/settings.json" "${cursor_config_path}/settings.json"
    fi
fi

log info "Linking gitconfig"
ln -sf "${REPOS_HOME}/env/dotfiles/gitconfig" "${HOME}/.gitconfig"

log info "Linking vimrc"
ln -sf "${REPOS_HOME}/env/dotfiles/vimrc" "${HOME}/.vimrc"

log info "Cloning Vundle.vim"
if [ -d "${HOME}/.vim/bundle/Vundle.vim" ]; then
    log warning "Vundle.vim already exists, skipping clone step"
else
    log info "Cloning Vundle.vim"
    git clone https://github.com/VundleVim/Vundle.vim.git "${HOME}/.vim/bundle/Vundle.vim"
fi

if command -v nix >/dev/null 2>&1; then
    log warning "nix already installed, skipping installation step"
else
    log info "Installing nix"
    install_nix
fi
