# Tool preferences

This environment uses Nix (flakes) for package management. Tools are provided
by three profiles defined in the flake at
`/Users/sergei.belokon/rps/github.com/enkron/env/flake.nix`:

- `enk-coreutils-stable`: pinned to nixos-25.05. Core CLI utilities: btop,
  cdrtools, delta, difftastic, dust, fd, git, git-lfs, gnupg, groovy,
  hyperfine, jq, newsboat, nmap, nushell, podman, procs, qemu, ripgrep, sd,
  socat, tokei, tree, vim, w3m, yq-go, zoxide, zstd.
- `enk-coreutils-unstable`: tracks nixpkgs-unstable. Language toolchains and
  fast-moving tools: awscli2, bat, cilium-cli, claude-code, codex, fzf, go,
  gofumpt, gopls, hubble, jujutsu, k9s, kubectl, kubernetes-helm, nixd,
  nodejs_24, rumdl, rustup, talosctl, tealdeer, terraform, terraform-ls,
  tmux, zig, zls (plus `container` on aarch64-darwin).
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
| `cd` history      | `zoxide`    | stable    | frecency-based directory jumping     |
| `man` (quick)     | `tldr`      | unstable  | tealdeer, concise example pages      |
| manual JSON parse | `jq`        | stable    | always available                     |
| manual YAML parse | `yq`        | stable    | go-yq variant                        |

Use `fzf` (unstable) for interactive selection when multiple results are
expected and user input is appropriate.

For version control, `git` is canonical; `jj` (jujutsu) is available when the
user opts into it explicitly.

Do not fall back to legacy tools "for compatibility". This is a single-user
workstation, not a portable script target.

# Typography

Do not use Unicode hyphen/dash variants in documents or source code files
(including code comments). The forbidden characters are em dash, en dash,
hyphen, non-breaking hyphen, figure dash, minus sign, and any other
Unicode dash. Always use the plain ASCII hyphen-minus '-'.
