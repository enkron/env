vim9script

# Plugin manager: clones/updates the repos below into ~/.vim/pack via git.
const RepoPrefix = 'https://github.com/'
const PackageRoot = expand('~/.vim/pack/vendor')
const StartDir = PackageRoot .. '/start'
const PluginRepos = [
\   'rust-lang/rust.vim',
\   'ziglang/zig.vim',
\   'fatih/vim-go',
\   'jiangmiao/auto-pairs',
\   'enkron/ecs.vim',
\   'tpope/vim-obsession.git',
\   'sheerun/vim-polyglot',
\   'dense-analysis/ale',
\   'yegappan/lsp',
\]
# Add plugins by appending 'owner/repo' to s:PluginRepos above.
# Run :PluginsUpdate to clone or refresh every plugin via git.

def PluginName(repo: string): string
    const parts = split(repo, '/')
    var name = parts[len(parts) - 1]
    if name =~ '\.git$'
        name = substitute(name, '\.git$', '', '')
    endif
    return name
enddef

def PluginPath(repo: string): string
    return StartDir .. '/' .. PluginName(repo)
enddef

def EnsureStartDir()
    if !isdirectory(StartDir)
        mkdir(StartDir, 'p')
    endif
enddef

const PluginSpinnerFrames = ['⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇', '⠏']
var PluginUpdateRunning = false
var PluginUpdateQueue: list<string> = []
var PluginUpdateTotal = 0
var PluginUpdateIndex = -1
var PluginUpdateCurrentRepo = ''
var PluginUpdateCurrentName = ''
var PluginUpdateCurrentUrl = ''
var PluginUpdateSpinnerIndex = 0
var PluginUpdateTimer = -1
var PluginUpdateOutput: list<string> = []
var PluginUpdateFailures: list<string> = []

def RenderPluginUpdateStatus(marker: string)
    echohl None
    echo printf('%s / %s %s [%d/%d]',
        PluginUpdateCurrentName,
        PluginUpdateCurrentUrl,
        marker,
        PluginUpdateIndex + 1,
        PluginUpdateTotal)
    redraw
enddef

def StopPluginUpdateTimer()
    if PluginUpdateTimer != -1
        timer_stop(PluginUpdateTimer)
        PluginUpdateTimer = -1
    endif
enddef

def PluginUpdateSpinnerTick(_timer: number)
    if !PluginUpdateRunning
        return
    endif
    PluginUpdateSpinnerIndex = (PluginUpdateSpinnerIndex + 1) % len(PluginSpinnerFrames)
    RenderPluginUpdateStatus(PluginSpinnerFrames[PluginUpdateSpinnerIndex])
enddef

def PluginUpdateOnOutput(_channel: channel, msg: string)
    if !empty(msg)
        add(PluginUpdateOutput, msg)
    endif
enddef

def ClearPluginUpdateCmdline(_timer: number)
    if !PluginUpdateRunning
        echohl None
        echo ''
        redraw
    endif
enddef

def PluginsUpdateFinish()
    PluginUpdateRunning = false
    StopPluginUpdateTimer()
    packloadall
    if empty(PluginUpdateFailures)
        echohl None
        echom printf('Plugins updated (%d/%d).', PluginUpdateTotal, PluginUpdateTotal)
        echohl None
    else
        echohl ErrorMsg
        echom printf('Plugins updated with %d failure(s).', len(PluginUpdateFailures))
        for failure in PluginUpdateFailures
            echom '  ' .. failure
        endfor
        echohl None
    endif
    timer_start(1200, ClearPluginUpdateCmdline)
enddef

def StartNextPluginUpdate()
    PluginUpdateIndex += 1
    if PluginUpdateIndex >= PluginUpdateTotal
        PluginsUpdateFinish()
        return
    endif

    const repo = PluginUpdateQueue[PluginUpdateIndex]
    const target = PluginPath(repo)
    PluginUpdateCurrentRepo = repo
    PluginUpdateCurrentName = PluginName(repo)
    PluginUpdateCurrentUrl = RepoPrefix .. repo
    PluginUpdateOutput = []
    PluginUpdateSpinnerIndex = 0
    RenderPluginUpdateStatus(PluginSpinnerFrames[PluginUpdateSpinnerIndex])

    StopPluginUpdateTimer()
    PluginUpdateTimer = timer_start(120, PluginUpdateSpinnerTick, {repeat: -1})

    var cmd: list<string>
    if isdirectory(target .. '/.git')
        cmd = ['git', '-C', target, 'pull', '--ff-only']
    else
        cmd = ['git', 'clone', '--depth', '1', PluginUpdateCurrentUrl, target]
    endif

    var job = job_start(cmd, {
        out_cb: PluginUpdateOnOutput,
        err_cb: PluginUpdateOnOutput,
        out_mode: 'nl',
        err_mode: 'nl',
        exit_cb: PluginUpdateOnExit,
    })
    if type(job) != v:t_job || job_status(job) ==# 'fail'
        StopPluginUpdateTimer()
        echohl ErrorMsg
        echom printf('[%d/%d] %s ✗ failed to start git job',
            PluginUpdateIndex + 1,
            PluginUpdateTotal,
            PluginUpdateCurrentName)
        echohl None
        add(PluginUpdateFailures, printf('%s: unable to start job', PluginUpdateCurrentRepo))
        StartNextPluginUpdate()
    endif
enddef

def PluginUpdateOnExit(_job: job, status: number)
    StopPluginUpdateTimer()
    if status == 0
        echohl None
        echom printf('[%d/%d] %s ✓ done',
            PluginUpdateIndex + 1,
            PluginUpdateTotal,
            PluginUpdateCurrentName)
        echohl None
    else
        const details = empty(PluginUpdateOutput) ? '' : ': ' .. PluginUpdateOutput[-1]
        echohl ErrorMsg
        echom printf('[%d/%d] %s ✗ failed%s',
            PluginUpdateIndex + 1,
            PluginUpdateTotal,
            PluginUpdateCurrentName,
            details)
        echohl None
        add(PluginUpdateFailures, printf('%s (exit %d)', PluginUpdateCurrentRepo, status))
    endif
    redraw
    StartNextPluginUpdate()
enddef

def PluginsUpdate()
    if !executable('git')
        echohl ErrorMsg
        echom 'git executable not found; cannot install plugins.'
        echohl None
        return
    endif
    if PluginUpdateRunning
        echohl WarningMsg
        echom 'PluginsUpdate is already running.'
        echohl None
        return
    endif
    EnsureStartDir()
    PluginUpdateQueue = copy(PluginRepos)
    PluginUpdateTotal = len(PluginUpdateQueue)
    if PluginUpdateTotal == 0
        echom 'No plugins configured.'
        return
    endif
    PluginUpdateIndex = -1
    PluginUpdateFailures = []
    PluginUpdateRunning = true
    echom printf('Updating %d plugin(s)...', PluginUpdateTotal)
    StartNextPluginUpdate()
enddef

command! PluginsUpdate call PluginsUpdate()
