# Tool preferences

This environment uses Nix (flakes) for package management. Tools are provided
by three profiles defined in the flake at
`/Users/sergei.belokon/rps/github.com/enkron/env/flake.nix`:

- `enk-coreutils-stable`: pinned to nixos-25.05. Core CLI utilities: btop,
  cdrtools, delta, difftastic, dust, fd, git, git-lfs, gnupg, groovy,
  hyperfine, jq, newsboat, nmap, nushell, podman, procs, qemu, ripgrep, sd,
  skopeo, socat, tokei, tree, viddy, vim, w3m, yq-go, zoxide, zstd.
- `enk-coreutils-unstable`: tracks nixpkgs-unstable. Language toolchains and
  fast-moving tools: argocd, awscli2, bat, cilium-cli, claude-code, codex,
  fzf, go, gofumpt, gopls, hubble, jujutsu, k9s, kubectl, kubernetes-helm,
  nixd, nodejs_24, rumdl, rustup, talosctl, tealdeer, terraform,
  terraform-ls, tmux, zig, zls (plus `container` on aarch64-darwin).
- `enk-coreutils-dev`: experimental/temporary toolchains (currently chafa,
  zellij).

When using the Bash tool, prefer modern alternatives over legacy coreutils:

| Instead of        | Use         | Profile   | Notes                                |
|-------------------|-------------|-----------|--------------------------------------|
| `grep`            | `rg`        | stable    | ripgrep, faster, respects .gitignore |
| `find`            | `fd`        | stable    | simpler syntax, respects .gitignore  |
| `cat`             | `bat`       | unstable  | syntax highlighting, git integration |
| `sed`             | `sd`        | stable    | simpler regex syntax (no escaping)   |
| `du`              | `dust`      | stable    | visual disk usage                    |
| `top` / `htop`    | `btop`      | stable    | resource monitor                     |
| `ps`              | `procs`     | stable    | modern process viewer                |
| `diff`            | `delta`     | stable    | also configured as git pager         |
| `diff` (semantic) | `difft`     | stable    | difftastic, syntax-aware diffs       |
| `time` (bench)    | `hyperfine` | stable    | statistical command benchmarking     |
| `wc -l` (code)    | `tokei`     | stable    | language-aware line counts           |
| `watch`           | `viddy`     | stable    | modern watch, highlights diffs       |
| `cd` history      | `zoxide`    | stable    | frecency-based directory jumping     |
| `man` (quick)     | `tldr`      | unstable  | tealdeer, concise example pages      |
| manual JSON parse | `jq`        | stable    | always available                     |
| manual YAML parse | `yq`        | stable    | go-yq variant                        |

Use `fzf` (unstable) for interactive selection when multiple results are
expected and user input is appropriate.

For version control, prefer `jj` (jujutsu, unstable) where it can act as a
drop-in for the needed operation. Fall back to `git` when `jj` cannot: it has
no support for the Git LFS extension, and some git-specific commands or
techniques (eg. interactive rebase workflows, certain hooks) have no `jj`
equivalent in a git-backed repo.

Do not fall back to legacy tools "for compatibility". This is a single-user
workstation, not a portable script target.

# Version control boundaries

Claude must never execute any state-changing Git or JJ (Jujutsu) operation,
under any circumstances - this includes (non-exhaustively) rebase, commit,
describe, new, edit, abandon, squash, restore, branch/bookmark create or
move, merge, and push. This applies even when the operation looks safe,
trivial, or easily reversible (eg. `jj undo` exists) - reversibility is not
the test; execution itself is prohibited. These actions are the user's sole
responsibility. Claude may explain the current repository state, describe
what a candidate operation would do, and draft or suggest the exact
command(s) to run (including commit messages/descriptions), but must always
stop there and let the user run it themselves - never execute it on their
behalf, and never change repository state without the user's explicit
approval for that specific action. Read-only/inspection commands (eg. `git
status`, `git log`, `git diff`, `git show`, `jj log`, `jj st`, `jj diff`,
`jj op log`, `jj bookmark list`) remain fine to run without asking.

# Infrastructure boundaries

Claude must never execute infrastructure rollout/apply commands (eg.
`terraform apply`, `terraform destroy`, `pulumi up`, `kubectl apply`,
`helm install`/`upgrade`, `argocd app sync`, or any equivalent command that
provisions, mutates, or tears down real infrastructure), under any
circumstances. These actions are the user's sole responsibility. Claude may
draft, explain, or suggest the exact command to run (eg. show a `terraform
plan`/`apply` invocation) but must never execute it itself. Read-only or
inspection commands (eg. `terraform plan`, `terraform show`, `kubectl get`,
`kubectl describe`) are fine to run.

# Typography

Do not use Unicode hyphen/dash variants in documents or source code files
(including code comments). The forbidden characters are em dash, en dash,
hyphen, non-breaking hyphen, figure dash, minus sign, and any other
Unicode dash. Always use the plain ASCII hyphen-minus '-'.

# Line width

Wrap comments, docstrings and prose to the width Vim applies to that
file type, not to a generic 79/80:

- 99 columns by default, for every file type (`set textwidth=99` in
  `dotfiles/vimrc`).
- 79 for markdown (`dotfiles/vim/plugin/prose.vim`; the rumdl ALE fixer
  reflows to the same `MD013.line-length = 79` on save).
- 72 for git commit messages and jj descriptions (Vim's builtin
  `gitcommit` and `jjdescription` ftplugins).
- yaml is never reflowed: yamlfmt leaves long scalars alone and
  yamllint only warns past 120 (`dotfiles/yamllint.yaml`).

This governs prose only - comments, docstrings, documentation, commit
messages. Leave code lines to the language's formatter (rustfmt,
gofumpt, ruff, yamlfmt) and do not hand-break them to hit these
numbers. Unbreakable tokens (URLs, image references, table rows, long
identifiers) may exceed the width.

An explicit project convention outranks these defaults: a formatter or
linter config in the repo (`rustfmt.toml`, `.editorconfig`, a
`line-length` in `pyproject.toml`), or a width the file being edited
plainly already follows. Match the file being edited; do not reformat
it. Never reflow lines the current change does not otherwise touch.

When the width is unclear, ask Vim instead of guessing:

    vim -es -u ~/.vimrc -i NONE -c 'edit <file>' \
        -c 'redir >> /dev/stdout' -c 'echo &tw' -c 'redir END' -c 'qa!'
