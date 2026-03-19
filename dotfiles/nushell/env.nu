# Nushell Environment Configuration

# Prioritize Nix paths over system defaults
$env.PATH = ($env.PATH
    | prepend "/nix/var/nix/profiles/default/bin"
    | prepend $"($env.HOME)/.nix-profile/bin"
)

# Rust/Cargo
if ($"($env.HOME)/.cargo/bin" | path exists) {
    $env.PATH = ($env.PATH | prepend $"($env.HOME)/.cargo/bin")
}

# Deduplicate PATH entries (Zsh: typeset -U path)
$env.PATH = ($env.PATH | uniq)

# Default editor
$env.EDITOR = "vim"

# macOS ls colours (BSD ls uses CLICOLOR/LSCOLORS; GNU ls uses LS_COLORS)
if ((sys host).name == "Darwin") {
    $env.CLICOLOR = "1"
    $env.LSCOLORS = "ExGxFxDxCxDbDaabagacBd"
}

# Command-line fuzzy finder defaults
# https://github.com/junegunn/fzf
$env.FZF_DEFAULT_OPTS = '--height=40% --layout=reverse --info=inline-right --color=16 --pointer="" --cycle'

# bat: syntax-highlighted cat(1)
# https://github.com/sharkdp/bat
$env.BAT_THEME_DARK = "Nord"

# Prompt: red "»" (Zsh: PS1="%F{red}»%f ")
$env.PROMPT_COMMAND = {|| "" }
$env.PROMPT_INDICATOR = {|| $"(ansi red)»(ansi reset) " }
$env.PROMPT_COMMAND_RIGHT = {|| "" }
$env.PROMPT_MULTILINE_INDICATOR = {|| ": " }
