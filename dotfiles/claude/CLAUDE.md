# Global instructions

## Environment

Single-user workstation. CLI tools come from Nix flake profiles. If a tool
is missing, say so and suggest adding it to the flake; never install via
brew, npm -g, pip or curl.

Use modern tools and never fall back to legacy ones "for compatibility":
rg not grep, fd not find, sd not sed, bat -pp not cat, jq/yq for JSON/YAML,
delta/difft for diffs, hyperfine for timing, tokei for line counts.

Prefer jj; use git only where jj cannot (Git LFS, hooks, git-only commands).

## Boundaries

State-changing VCS and infrastructure operations are my responsibility.
Draft the exact command and stop; do not run it, even if it is trivially
reversible (`jj undo`). This covers jj new/edit/rebase/squash/abandon/
restore/split, bookmark changes, git rebase/merge/reset/checkout/push, and
terraform apply/destroy, kubectl apply/delete/patch, helm install/upgrade,
argocd app sync and their equivalents. Read-only inspection (status, log,
diff, show, op log, terraform plan, kubectl get/describe) is fine.

Exception: to record session work you may run `jj describe`/`jj commit` on
the working-copy change, or `git add <files you changed>` then `git commit`.
Never use --amend, --no-verify or `git add -A`/`.`, and never reword commits
that are mine, pushed or immutable.

## Commit messages

Conventional Commits 1.0.0 with a scope nested at most two levels:

    type(scope(sub)): imperative lower-case subject, no period

    Body wrapped at 72: what changed and why, plus what the diff cannot
    show. Omit only for a self-evident one-liner.

    * optional changeset item

    Refs: TICKET-123
    Co-Authored-By: <attribution>

- Header at most 72 columns. Breaking: `!` before `:` and a
  `BREAKING CHANGE:` trailer.
- Scope: take it from the repo CLAUDE.md, else the most common scope in the
  log for the same paths; never invent a new top-level scope.
- One logical change per commit. Mention Claude only in the trailer.

## Line width

Wrap prose (comments, docs, commit messages) at 99 columns by default, 79
in markdown and 72 in commit messages; never reflow YAML. A repo formatter
config, or the width the file already follows, takes precedence. Never
hand-wrap code or reflow lines the change does not touch.
