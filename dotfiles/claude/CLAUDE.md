# Tool preferences

This environment uses Nix (flakes) for package management. All tools below are
available system-wide via the `enk-coreutils` profile.

When using the Bash tool, prefer modern alternatives over legacy coreutils:

| Instead of       | Use              | Notes                              |
|------------------|------------------|------------------------------------|
| `grep`           | `rg`             | ripgrep — faster, respects .gitignore |
| `find`           | `fd`             | simpler syntax, respects .gitignore |
| `cat`            | `bat`            | syntax highlighting, git integration |
| `sed`            | `sd`             | simpler regex syntax (no escaping) |
| `du`             | `dust`           | visual disk usage                  |
| `top` / `htop`   | `btop`          | resource monitor                   |
| `diff`           | `delta`          | also configured as git pager       |
| manual JSON parse | `jq`            | always available                   |
| manual YAML parse | `yq`            | go-yq variant                      |

Use `fzf` for interactive selection when multiple results are expected and user
input is appropriate.

Do not fall back to legacy tools "for compatibility" — this is a single-user
workstation, not a portable script target.
