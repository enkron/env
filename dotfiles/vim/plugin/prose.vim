vim9script

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
