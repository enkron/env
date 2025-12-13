#!/bin/sh

REPOS_HOME="${HOME}/rps/github.com/enkron"

log() {
    case "$1" in
        info)
            printf "\033[1;32minfo:\033[0m %s\n" "$2"
            ;;
        warning)
            printf "\033[1;33mwarning:\033[0m %s\n" "$2"
            ;;
        error)
            printf "\033[1;31merror:\033[0m %s\n" "$2"
            ;;
        *)
            printf "\033[1;37mdebug:\033[0m %s\n" "$2"
            ;;
    esac
}

install_nix() {
    curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | \
        sh -s -- install --determinate --no-confirm
}

# As of Determinate Systems 3.6.2 version installer requires login to the
# Flakehub account to upgrade the nix version using the `sudo determinate-nixd upgrade`
# command. This function is a workaround to upgrade nix.
# https://manual.determinate.systems/installation/upgrading
upgrade_nix() {
    if ! command -v nix >/dev/null 2>&1; then
        log error "nix is not installed, cannot upgrade"
        exit 1
    fi

    log info "Upgrading nix"
    # Update 7.X.2025: a corresponding workaround for the anonymous upgrades is merged, therefore
    # it's now possible to upgrade Determinate Nix using standard method.
    #sudo rm /nix/receipt.json && install_nix
    sudo determinate-nixd upgrade
}

while [ "$#" -gt 0 ]; do
    case "$1" in
        --upgrade-nix)
            upgrade_nix
            exit 0
            ;;
        *)
            log error "Unknown option: $1"
            exit 1
            ;;
    esac
    shift
done

if [ -d "${REPOS_HOME}/env" ]; then
    log warning "env repository already exists, skipping clone step"
else
    # Check if the repository is accessible by ssh, clone the https endpoint otherwise
    log info "Cloning env repository"
    ssh -T git@github.com >/dev/null 2>&1; if [ $? -eq '1' ]; then
        git clone git@github.com:enkron/env.git "${REPOS_HOME}/env"
    else
        git clone https://github.com/enkron/env.git "${REPOS_HOME}/env"
    fi
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

    # Setup zshrc file in the user's home
    log info "Linking zshrc"
    ln -sf "${REPOS_HOME}/env/dotfiles/Darwin/zshrc" "${HOME}/.zshrc"

    log info "Installing fonts"
    # Setup "Hack" font family
    cp -R "${REPOS_HOME}/env/fonts/hack-v3.003-ttf" "${HOME}/Library/Fonts/Hack"
fi

if [ "$(uname -s)" = 'Linux' ]; then
    if command -v cursor >/dev/null 2>&1; then
        cursor_config_path="${HOME}/.config/Cursor/User"

        log info "Linking Cursor keybindings"
        ln -sf "${REPOS_HOME}/env/dotfiles/cursor/keybindings.json" "${cursor_config_path}/keybindings.json"

        log info "Linking Cursor settings"
        ln -sf "${REPOS_HOME}/env/dotfiles/cursor/settings.json" "${cursor_config_path}/settings.json"
    fi
fi

log info "Linking Git configuration"
ln -sf "${REPOS_HOME}/env/dotfiles/gitconfig" "${HOME}/.gitconfig"

log info "Linking Vim configuration"
ln -sf "${REPOS_HOME}/env/dotfiles/vimrc" "${HOME}/.vimrc"

if [ -d "${HOME}/.vim/bundle/Vundle.vim" ]; then
    log warning "Vundle.vim already exists, skipping clone step"
else
    log info "Cloning Vundle.vim"
    git clone https://github.com/VundleVim/Vundle.vim.git "${HOME}/.vim/bundle/Vundle.vim"
fi

if [ -d "${HOME}/.tmux/plugins/tpm" ]; then
    log warning "TPM already exists, skipping clone step"
else
    log info "Cloning Tmux Plugin Manager"
    git clone https://github.com/tmux-plugins/tpm "${HOME}/.tmux/plugins/tpm"
fi

log info "Linking Tmux configuration"
ln -sf "${REPOS_HOME}/env/dotfiles/tmux.conf" "${HOME}/.tmux.conf"

log info "Linking Jujutsu configuration"
mkdir -p "${HOME}/.config/jj"
ln -sf "${REPOS_HOME}/env/dotfiles/jj.toml" "${HOME}/.config/jj/config.toml"

log info "Linking Ghostty configuration"
mkdir -p "${HOME}/.config/ghostty"
ln -sf "${REPOS_HOME}/env/dotfiles/ghostty.conf" "${HOME}/.config/ghostty/config"

log info "Linking Newsboat configuration"
mkdir -p "${HOME}/.newsboat"
ln -sf "${REPOS_HOME}/env/dotfiles/newsboat/urls" "${HOME}/.newsboat/urls"
ln -sf "${REPOS_HOME}/env/dotfiles/newsboat/config" "${HOME}/.newsboat/config"

if command -v nix >/dev/null 2>&1; then
    log warning "nix already installed, skipping installation step"
else
    log info "Installing nix"
    install_nix
fi
