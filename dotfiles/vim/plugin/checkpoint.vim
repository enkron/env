vim9script

# Checkpoint: a non-destructive undo barrier.
#
# <leader>u writes the buffer if it is modified and pins the resulting undo state as a floor for
# that buffer. While the floor is armed, Normal-mode `u` refuses to leave the buffer in a state
# older than it and says so instead. <leader>U removes the floor again. Nothing is ever dropped
# from the undo tree: every state that existed before the barrier stays reachable through the
# deliberate time-travel commands, which are left unguarded on purpose (see the escape hatches at
# the end of this block).
#
# This replaces <leader>ee (:setl undoreload=0 |edit), which did the opposite of what its comment
# claimed: it never wrote, aborted with E37 on a modified buffer, left 'undoreload' at 0 for the
# rest of the buffer's life, and threw the undo tree away. With 'noswapfile', 'nobackup' and no
# 'undofile' anywhere in this config, that history was gone for good.
#
# Why one sequence number is enough, and why the test is changenr() <= barrier:
#
# Undo sequence numbers are handed out monotonically per buffer and are never reused, not even
# after the tree is cleared (:h :undolist, "This number continuously increases"). Along any one
# root-to-leaf path they are therefore strictly increasing, and `u` walks exactly one node up the
# current path; it is `g-` that walks in time order and hops between branches (:h undo-branches).
# So on the checkpoint's own line of history "older than the barrier" is exactly "sequence number
# below the barrier", and because `u` moves one node at a time it can never jump over the barrier
# node from above, only land on it. Refusing the step out of that node is therefore enough, it
# costs one changenr() call, and it needs no walk of undotree().entries.
#
# Branching does not break this. Checkpoint at #2, edit up to #5, undo back to #2, then type
# something new: the new state is #6 with #2 as its parent, and #3..#5 survive as a sibling
# branch. `u` from #6 lands on #2 (its parent, not #5), where it is refused again. The naive
# design, undo first and then :undo {barrier} when changenr() dropped below it, breaks exactly
# here: :undo {N} is a jump to an arbitrary node, so it can teleport the buffer onto another
# branch. It also fires the change autocmds twice (this config formats on write and drives LSP
# diagnostics off buffer changes) and raises E830 once the barrier has been freed.
#
# The barrier is armed as a buffer-local mapping of `u`, not a global one. With no checkpoint set
# there is no mapping at all, so `u` keeps its stock behaviour and its stock messages everywhere,
# including help, quickfix and terminal buffers, and a plugin's own buffer-local `u` is only ever
# shadowed in a buffer that was checkpointed on purpose.
#
# Escape hatches, all deliberate, all documented rather than guarded:
#   g-, :earlier {N}, :earlier 10m, :earlier 1f   travel in time order, crosses branches
#   :undo {N}                                     explicit jump to one numbered state
#   <leader>U                                     lift the barrier
# A checkpoint always writes, so the barrier node carries a "save" mark: :earlier 1f is the
# shortest way back to it and :later 1f returns. `U` (undo-line) needs no guard either: it is
# itself a change, so it only ever moves forward in the tree and can be undone, not crossed.

def Warn(msg: string)
    echohl WarningMsg
    echomsg 'checkpoint: ' .. msg
    echohl None
enddef

def Info(msg: string)
    echohl MoreMsg
    echomsg 'checkpoint: ' .. msg
    echohl None
enddef

# The barrier lives on the buffer, so two buffers hold independent barriers and the state dies
# with the buffer. Its absence means "no barrier".
def Barrier(): number
    return get(b:, 'checkpoint_seq', -1)
enddef

# Does {seq} still exist anywhere in this buffer's undo tree? undotree().entries is a chain of
# entries along the current branch, oldest first, and any entry may carry an "alt" list holding a
# branch that forks off the same parent (:h undotree()). The question here is existence, not
# ancestry, so the walk has to descend into "alt" as well.
def HasSeq(entries: list<any>, seq: number): bool
    for entry in entries
        if entry.seq == seq
            return true
        endif
        if has_key(entry, 'alt') && HasSeq(entry.alt, seq)
            return true
        endif
    endfor
    return false
enddef

# A barrier goes stale when the tree it points into is gone: :e! clears the tree outright once
# the file crosses 'undoreload', and 'undolevels' frees the oldest states as editing continues.
# Neither resets seq_cur or seq_last, so after a clear undotree() still reports the old numbers
# with an empty "entries" list; emptiness and membership are the tests, not seq_last alone.
def Alive(seq: number): bool
    # 0 is the state before the first change. It exists for as long as the buffer does.
    if seq < 1
        return true
    endif
    const tree = undotree()
    return !empty(tree.entries) && seq <= tree.seq_last && HasSeq(tree.entries, seq)
enddef

def Arm(seq: number)
    b:checkpoint_seq = seq
    # <ScriptCmd> rather than <Cmd> because Undo() is script-local, and rather than <expr>
    # because the guard has to change text. v:count1 is readable from both (:h <ScriptCmd>), and
    # neither is echoed, so <silent> would be redundant (:h <Cmd>).
    nnoremap <buffer> u <ScriptCmd>Undo()<CR>
enddef

def Disarm()
    if exists('b:checkpoint_seq')
        unlet b:checkpoint_seq
    endif
    # silent! because E31 is the expected outcome when the mapping was already taken away.
    silent! nunmap <buffer> u
enddef

def SetCheckpoint()
    # Special buffers are refused up front, and not only because writing them is meaningless: on
    # a 'buftype' of nofile :update reports success and clears 'modified' without writing a byte,
    # which would arm a barrier promising a saved state that does not exist.
    if &buftype != ''
        Warn(printf('%s buffer cannot be checkpointed, no barrier set', &buftype))
        return
    endif
    if empty(bufname())
        Warn('buffer has no file name, no barrier set')
        return
    endif
    const dirty = &modified
    try
        # :update writes only when modified, which is exactly the wanted behaviour. It is
        # silenced so the confirmation below is the only message: two messages from one mapping
        # cost a hit-enter prompt.
        silent update
    catch
        # E45 ('readonly' set), E212 (cannot open for writing) and friends land here. The
        # barrier is deliberately not armed, so it never promises a state that missed the disk.
        Warn('write failed, no barrier set: ' .. v:exception)
        return
    endtry
    if &modified
        Warn('buffer still modified after the write, no barrier set')
        return
    endif
    # After the write, not before: BufWritePre formatting (gopls through plugin/lsp.vim, ALE
    # fix-on-save) adds undo states of its own, and the barrier has to be the state that
    # actually reached the disk.
    Arm(changenr())
    Info(printf('barrier at #%d%s', changenr(), dirty ? ' (written)' : ''))
enddef

def LiftBarrier()
    const barrier = Barrier()
    if barrier < 0
        Info('no barrier set')
        return
    endif
    Disarm()
    Info(printf('barrier at #%d lifted', barrier))
enddef

def Undo()
    const want = v:count1
    const barrier = Barrier()
    # No barrier, or a barrier on the state before the first change, which nothing is older than.
    if barrier < 1
        execute 'normal! ' .. want .. 'u'
        return
    endif
    if changenr() <= barrier && !Alive(barrier)
        # The tree the barrier pointed into is gone; heal instead of refusing forever. The undo
        # is silenced so that the explanation is the message that stays on screen.
        Disarm()
        silent execute 'normal! ' .. want .. 'u'
        Warn('undo history was reset, barrier dropped')
        return
    endif
    # A count is clamped, not refused: 3u two steps above the barrier undoes those two steps and
    # stops there. Vim prints its own summary for the last step and the earlier ones are
    # silenced, because stacked messages would end in a hit-enter prompt.
    var moved = 0
    while moved < want && changenr() > barrier
        const before = changenr()
        if moved == want - 1
            undo
        else
            silent undo
        endif
        if changenr() == before
            # Nothing left to undo; Vim has already said so.
            break
        endif
        moved += 1
    endwhile
    if moved == 0 && changenr() < barrier
        Warn(printf('already behind barrier #%d; g- travels, <leader>U lifts', barrier))
    elseif moved == 0
        Warn(printf('barrier at #%d; <leader>U lifts it', barrier))
    elseif moved < want
        Warn(printf('stopped at barrier #%d after %d of %d', barrier, moved, want))
    endif
enddef

# Item for plugin/statusline.vim: "#47" armed and ahead of the barrier, "#47=" sitting on it so
# `u` will refuse, "#47!" behind it, which only an escape hatch can arrange. The padding is part
# of the string so the item collapses to nothing when no barrier is set. Deliberately O(1): the
# statusline is re-evaluated on every cursor move, while undotree() rebuilds the whole tree on
# every call.
def g:CheckpointStatus(): string
    const barrier = get(b:, 'checkpoint_seq', -1)
    if barrier < 0
        return ''
    endif
    const cur = changenr()
    return printf(' #%d%s ', barrier, cur == barrier ? '=' : (cur < barrier ? '!' : ''))
enddef

augroup enk_checkpoint
    autocmd!
    # :e! can clear the undo tree outright, which would leave a mapping guarding a state that no
    # longer exists. The exists() test short-circuits for every buffer that was never
    # checkpointed, so undotree() is not called on ordinary reloads.
    autocmd BufReadPost * {
        if exists('b:checkpoint_seq') && !Alive(b:checkpoint_seq)
            Disarm()
        endif
    }
augroup END

# Known limitations and deliberate escape hatches:
# - Only `u` is guarded. g-, :earlier (including 10m and 1f), :undo {N} and <leader>U all reach
#   states behind the barrier on purpose. g+, CTRL-R and :later are never blocked.
# - After travelling behind the barrier with an escape hatch and then making a new change there,
#   one `u` from that new state can land below the barrier, because its parent already is. The
#   floor holds again from then on. Closing this would mean reading the parent out of undotree()
#   on every `u` and refusing to undo a change just made, which is worse.
# - `U` (undo-line) is not guarded and needs no guard: it is itself a change, so it moves forward
#   in the tree; `u` undoes it.
# - If 'undolevels' frees the barrier node itself, the barrier stops being reachable. Benign: the
#   states below it are freed first, so nothing older than it survives to travel to. Not noticed
#   until the next :e (BufReadPost) or a `u` that reaches it.
# - A formatter that edits the buffer asynchronously after :update returns leaves the barrier one
#   state early; press <leader>u again to move it.
# - A checkpoint taken with changenr() == 0 is vacuous: nothing is older, so `u` passes through.
# - Barriers are per buffer and do not survive :bwipeout or a restart. Neither does the undo
#   history, since this config sets no 'undofile'.
# - :mapclear <buffer> from another plugin would remove the guard while b:checkpoint_seq remains;
#   <leader>u re-arms it.

# Scriptable equivalents of the two mappings.
command! Checkpoint SetCheckpoint()
command! CheckpointLift LiftBarrier()

# Write the buffer and pin its undo history here: `u` will not take the text back past this
# state. Repeat to move the barrier forward.
nnoremap <leader>u <ScriptCmd>SetCheckpoint()<CR>
# Lift the barrier, so `u` is the stock command again.
nnoremap <leader>U <ScriptCmd>LiftBarrier()<CR>
