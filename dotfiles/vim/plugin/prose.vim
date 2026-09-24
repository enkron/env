vim9script

# Fenced code blocks tagged with one of these get that language's syntax
# instead of flat markdownCodeBlock. Each distinct syntax is loaded into
# every markdown buffer, so list only the fence languages actually written;
# aliases before '=' share one include. Left out on purpose: groovy (costs
# ~30ms alone), and python and diff, whose polyglot copies get included too
# and relink their groups session-wide (sh is disabled in polyglot instead).
g:markdown_fenced_languages = [
    'bash=sh', 'shell=sh', 'sh', 'rust', 'go', 'nix', 'yaml', 'toml',
    'json', 'vim', 'viml=vim', 'make', 'makefile=make', 'terraform',
    'hcl=terraform',
]

# Native complete-as-you-type (patch 9.1.1590) for prose buffers only;
# code buffers stay owned by yegappan/lsp's autoComplete machinery.
# One FileType autocmd instead of per-filetype after/ftplugin copies;
# it is defined after the ftplugin loader, so it still runs last.
augroup prose_autocomplete
    autocmd!
    autocmd FileType markdown,text,gitcommit {
        setlocal autocomplete
        setlocal spell
        setlocal complete=.^5,w^5,kspell^5
    }
    autocmd FileType markdown setlocal textwidth=79
augroup END
