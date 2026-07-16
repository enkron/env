vim9script

# Some Jenkins pipeline definitions are named <pipeline_name>.groovy rather than the bare
# `Jenkinsfile`, so Vim's builtin ftdetect (which always sets filetype=groovy for *.groovy) can't
# tell them apart from plain Groovy library code. vars/ and src/ are the directory names mandated
# by the Jenkins Shared Library layout, so anything under them is left as groovy; everything else
# is sniffed for pipeline DSL markers and, if found, forced to filetype=Jenkinsfile (vim-polyglot
# bundles a real Jenkinsfile syntax/indent for this).
#
# This deliberately lives in plugin/ with a private augroup instead of the ftdetect/ runtime
# directory: vim-polyglot resets the shared filetypedetect augroup (`au! filetypedetect` in
# autoload/polyglot/init.vim) when it loads after filetype.vim, which would erase any autocmd
# registered there via ~/.vim/ftdetect.
def DetectJenkinsfileGroovy()
    var path = expand('%:p')
    if path =~ '[\\/]\%(vars\|src\)[\\/]'
        return
    endif

    var lines = getline(1, 40)
    for line in lines
        if line =~ '^\s*package\s'
                    \ || line =~ '^\s*\%(class\|interface\|enum\)\s\+\w'
            return
        endif
    endfor

    for line in lines
        if line =~ '@Library('
                    \ || line =~ '^\s*pipeline\s*{\=\s*$'
                    \ || line =~ 'properties(\s*\['
                    \ || line =~ '\<node\s*(.*)\s*{'
                    \ || line =~ '\<stage\s*('
            setlocal filetype=Jenkinsfile
            return
        endif
    endfor
enddef

augroup jenkinsfile_groovy
    autocmd!
    autocmd BufNewFile,BufRead *.groovy call DetectJenkinsfileGroovy()
    autocmd BufNewFile,BufRead Jenkinsfile setlocal filetype=Jenkinsfile
augroup END
