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
- `enk-coreutils-dev`: experimental/temporary toolchains (currently chafa).

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

Claude must never create Git branches (or JJ bookmarks), commit changes, or
push to a remote, under any circumstances. These actions are the user's
sole responsibility. Claude may draft or suggest commit messages/descriptions
but must never execute the commit (or branch/push) itself.

# Typography

Do not use Unicode hyphen/dash variants in documents or source code files
(including code comments). The forbidden characters are em dash, en dash,
hyphen, non-breaking hyphen, figure dash, minus sign, and any other
Unicode dash. Always use the plain ASCII hyphen-minus '-'.
