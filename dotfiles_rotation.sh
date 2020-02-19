#!/bin/bash

main()
{
    local env_dir="$HOME/Documents/Environment"
    local rotation_files=".tmux.conf .bash_profile .zshrc .vimrc .local"

    local firefox_profile_home="$HOME/Library/Application Support/Firefox/Profiles"
    local firefox_profile_name=$(ls "$firefox_profile_home")
    
    local firefox_cfg="$firefox_profile_home/$firefox_profile_name/user.js"

    for dotf in $rotation_files; do
        local envf="$(echo $dotf |sed 's/.//')"
        rm -rf "$env_dir/dotfiles/$envf" #cleanup
        cp -fR "$HOME/$dotf" "$env_dir/dotfiles"
        mv "$env_dir/dotfiles/$dotf" "$env_dir/dotfiles/$envf"
    done

    cp "$firefox_cfg" "$env_dir/firefox"

    brew bundle dump && mv Brewfile "$env_dir/homebrew"
}


main
