vim9script

# Kubernetes/YAML ecosystem convention is 2-space indentation while the
# global default (vimrc) is 4. Vim's builtin ftplugin already applies
# shiftwidth=2/softtabstop=2 (g:yaml_recommended_style), but tabstop
# stays at the global 4; set the full trio explicitly so display, >>
# shifts and yamlfmt output all agree. As with prose.vim, this autocmd
# is registered after the ftplugin loader, so it runs last. `helm` is
# included: polyglot detects */templates/*.yaml as filetype helm, which
# also keeps the yaml linter/fixer away from Go-templated files.
augroup yaml_indent
    autocmd!
    autocmd FileType yaml,helm setlocal tabstop=2 softtabstop=2 shiftwidth=2 expandtab
augroup END
