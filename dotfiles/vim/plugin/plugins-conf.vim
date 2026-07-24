vim9script

# rust.vim
g:rustfmt_autosave = 1
g:rust_keep_autopairs_default = 0
g:rust_fold = 1

# vim-go
g:go_fmt_command = 'gofumpt'
g:go_fmt_autosave = 0                # gopls owns format-on-save via :LspFormat

# asm.vim
# set filetype=nasm
# let g:asmsyntax = 'nasm'

# ALE (Asynchronous Lint Engine)
# ALE is used *only* for linting. Actual LSP features (completion,
# go-to-definition, rename, references, etc.) come from vim-lsp.

g:ale_disable_lsp = 1                # Prevent ALE from acting as an LSP client
g:ale_completion_enabled = 0         # Disable ALE completion (vim-lsp handles it)
g:ale_hover_to_floating_preview = 1  # Keep ALE's hover popup (non-LSP)
g:ale_fix_on_save = 1                # Auto-fix when saving
g:ale_rust_cargo_use_clippy = executable('cargo-clippy')

g:ale_linters = {
\   'rust':   ['cargo'],
\   'python': ['ruff', 'mypy'],
\   'yaml':   ['yamllint']
\}

g:ale_fixers = {
\   '*':        ['remove_trailing_lines', 'trim_whitespace'],
\   'markdown': ['remove_trailing_lines', 'trim_whitespace', 'rumdl'],
\   'yaml':     ['remove_trailing_lines', 'trim_whitespace', 'yamlfmt']
\}

# reflow paragraphs that exceed the limit on save; paragraphs already
# within the limit are left untouched so intentional short lines survive
g:ale_markdown_rumdl_fmt_options = "--silent --config 'MD013.reflow = true' --config 'MD013.line-length = 79'"

# yamllint finds ~/.config/yamllint/config on its own; yamlfmt's global
# config discovery is less uniform across platforms, so pass the
# bootstrap-linked config explicitly to keep in-vim formatting
# deterministic (ALE runs `yamlfmt <options> -in`).
g:ale_yaml_yamlfmt_options = '-conf ' .. expand('~/.config/yamlfmt/.yamlfmt')
