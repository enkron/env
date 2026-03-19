# Nushell Shell Configuration
# Shell options, completions, keybindings, and aliases

# History (Zsh equivalents noted)
$env.config.history.max_size = 10_000          # HISTSIZE / SAVEHIST
$env.config.history.sync_on_enter = true       # INC_APPEND_HISTORY
$env.config.history.file_format = "sqlite"     # Structured storage
$env.config.history.isolation = true           # unsetopt SHARE_HISTORY

# Completions (Zsh: compinit + zstyle menu select + auto_menu)
# NOTE: For tool-specific completions (kubectl, terraform, cargo, etc.),
# consider installing carapace-bin as an external completer or sourcing
# completions from https://github.com/nushell/nu_scripts/tree/main/custom-completions
$env.config.completions.case_sensitive = false
$env.config.completions.quick = true
$env.config.completions.partial = true
$env.config.completions.algorithm = "prefix"
$env.config.completions.use_ls_colors = true

# Emacs keybinding mode (Zsh: bindkey -e)
$env.config.edit_mode = "emacs"

# Suppress startup banner
$env.config.show_banner = false

# Keybindings
$env.config.keybindings = [
    # Ctrl+L: clear scrollback (approximates Zsh clear_above with \e[1J)
    {
        name: clear_scrollback
        modifier: control
        keycode: char_l
        mode: [emacs vi_normal vi_insert]
        event: { send: clearscrollback }
    }
]

# NOTE: Nushell has a built-in Ctrl+R history search. FZF shell integration
# (Zsh: `source <(fzf --zsh)`) is not needed; Nushell's native search is
# comparable. If you prefer fzf for history, add a keybinding with
# `event: { send: executehostcommand, cmd: "commandline edit ..." }`.

# Aliases
# Prefer Podman over Docker (Docker is deprecated in this environment;
# use rootless Podman instead)
if (which podman | is-not-empty) {
    alias docker = podman
}

# Fallback to npx for AI coding tools when not installed natively
if (which claude | is-empty) {
    alias claude = npx @anthropic-ai/claude-code
}

if (which codex | is-empty) {
    alias codex = npx @openai/codex
}
