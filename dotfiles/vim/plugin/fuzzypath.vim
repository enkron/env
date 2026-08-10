vim9script

# Whole-path fuzzy completion for file names in Insert mode.
#
# Vim 9.2 already fuzzy-matches the *final* path component: 'completeopt'
# contains "fuzzy" (set in the vimrc), and since 'completefuzzycollect' was
# deprecated that flag implies fuzzy collection for "keyword,files,whole_line".
# So `src/mn` already completes to `src/main.rs` with plain i_CTRL-X_CTRL-F.
# What it cannot do is cross a '/': every ancestor component must be typed
# exactly, so `srcman` and `sr/main` both yield nothing.
#
# This closes that gap the way fzf.vim's fzf#vim#complete#path() does, but
# natively and without a plugin: collect the tree once with fd, fuzzy-filter
# it with matchfuzzy(), and hand the result back through 'completefunc'
# (:h complete-functions, :h matchfuzzy(), :h i_CTRL-X_CTRL-U). Returning
# "refresh": "always" makes Vim re-invoke the function on every keystroke, so
# narrowing keeps running matchfuzzy() instead of degrading to a prefix filter.
#
# i_CTRL-X_CTRL-F is shadowed because that is the key muscle memory already
# uses, and it is the key fzf.vim binds upstream. The stock per-component
# completion stays reachable on <C-x><C-g>.

# Candidates offered per invocation. matchfuzzy() over 50k paths costs about
# 9ms, so this cap is about popup legibility rather than speed.
const MaxCandidates = 100

# Guard against an accidental trigger in $HOME or /, where the scan would be
# effectively unbounded.
const MaxFiles = 50000

var cache: list<string> = []
var cache_root = ''

def Collect(): list<string>
    if executable('fd')
        # fd honours .gitignore, which is why 'wildignore' is deliberately
        # not consulted here.
        return systemlist('fd --type f --hidden --exclude .git --strip-cwd-prefix')
    endif
    # Self-contained fallback so the file still works without fd.
    return glob('**', 0, 1)->filter((_, v) => !isdirectory(v))
enddef

def Universe(): list<string>
    var root = getcwd()
    if root != cache_root || empty(cache)
        cache_root = root
        cache = Collect()
        if len(cache) > MaxFiles
            cache = cache[: MaxFiles - 1]
            echohl WarningMsg
            echomsg printf('fuzzypath: %s holds more than %d files, list truncated',
                root, MaxFiles)
            echohl None
        endif
    endif
    return cache
enddef

def Invalidate()
    cache = []
    cache_root = ''
enddef

# The 'base' argument is deliberately unused: Vim only fills it on the first
# call and passes an empty string on every refresh:'always' re-invocation, so
# trusting it leaves the list stuck at its unfiltered first result. The typed
# leader is read from the buffer instead. The signature is fixed by Vim
# (:h complete-functions), hence the unused parameter.
def g:FuzzyPathComplete(findstart: number, base: string): any
    # 'isfname' already contains '/', so \f spans a whole relative path - the
    # same span i_CTRL-X_CTRL-F itself uses. strpart() rather than a
    # [: col('.') - 2] slice because that slice returns the entire line when
    # the cursor sits in column 1.
    var before = strpart(getline('.'), 0, col('.') - 1)
    var start = match(before, '\f*$')

    # './foo' is how a relative path is habitually typed, but fd
    # --strip-cwd-prefix (and the glob() fallback) yield a bare 'foo', so a
    # literal './' would score against nothing.
    var lead = matchstr(strpart(before, start), '^\%(\./\)\+')

    if findstart
        # Start *after* the './' so it stays in the buffer rather than being
        # part of the replaced span. Including it breaks acceptance outright:
        # the candidate is silently never inserted. findstart must be a byte
        # index, which is what match() plus a byte length gives.
        return start + len(lead)
    endif

    # Absolute paths are left alone - they are outside this cwd-relative list,
    # so use <C-x><C-g> for those.
    var needle = strpart(before, start + len(lead))

    var words = empty(needle)
        ? Universe()[: MaxCandidates - 1]
        : matchfuzzy(Universe(), needle, {limit: MaxCandidates})

    return {
        words: words->mapnew((_, v) => ({word: v, menu: 'path'})),
        refresh: 'always',
    }
enddef

augroup enk_fuzzypath
    autocmd!
    # A new working directory means a different tree.
    autocmd DirChanged * Invalidate()
    # InsertLeave, not CompleteDone: nothing is in flight at that point, so
    # unlike the CompleteDone restore that used to cause E764 here, this
    # cannot race Vim's lookup of the option.
    autocmd InsertLeave * RestoreComplete()
augroup END

# The scan is cached, so files created after the first trigger need a nudge.
command! FuzzyPathReload Invalidate()

# Own the 'completefunc' slot outright. Nothing else in this config uses it
# (lsp drives 'omnifunc'), so there is nothing to preserve; a plugin that later
# sets it buffer-locally would take over <C-x><C-f>, which is fine and obvious.
set completefunc=g:FuzzyPathComplete

# The completion is driven through 'complete' rather than i_CTRL-X_CTRL-U
# because only 'complete' sources narrow as you type. <C-x><C-u> is one-shot:
# the first typed character ends it (CompleteDone fires immediately) and
# refresh:'always' is never honoured, so the popup just vanished. Per
# :h 'complete', an F{func} source may start at a non-keyword character and
# honours refresh:'always' - exactly what a path completion needs. Bare 'F'
# means "the function named in 'completefunc'", so the name is not duplicated.
var saved_complete = ''

def g:FuzzyPathTrigger(): string
    if empty(saved_complete)
        saved_complete = &l:complete
    endif
    &l:complete = 'F'
    return "\<C-n>"
enddef

# Restoring any earlier than InsertLeave reintroduces the E764-class race that
# an earlier CompleteDone restore caused here. The trade is that after one
# trigger, a plain <C-n> for the rest of that insert session offers paths
# rather than keywords; leaving Insert mode puts 'complete' back.
def RestoreComplete()
    if !empty(saved_complete)
        &l:complete = saved_complete
        saved_complete = ''
    endif
enddef

inoremap <expr> <C-x><C-f> g:FuzzyPathTrigger()
# Stock per-component completion. Non-recursive, so this reaches Vim's builtin
# rather than re-entering the mapping above.
inoremap <C-x><C-g> <C-x><C-f>
