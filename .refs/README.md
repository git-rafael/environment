# .refs/

This directory contains git submodules that track upstream repositories. Each submodule is organized as `.refs/<org>/<repo>/` and uses sparse-checkout — only the paths explicitly added are fetched locally.

Symlinks in `resources/` point into these directories to expose the content without duplicating it.

## Managing refs

Use `env-load refs` from the repo root (no Nix required):

```sh
env-load refs list                                     # list tracked refs and symlinks
env-load refs sync                                     # pull latest from all upstreams
env-load refs add anthropic/skills skills/mcp-builder  # add a path from an existing ref
env-load refs rm mcp-builder                           # remove symlink (submodule removed if empty)
```

Adding a path from a repo that isn't tracked yet will automatically add the submodule.

## Current refs

| Path | Upstream | Tracked paths |
|------|----------|---------------|
| [anthropic/skills](.refs/anthropic/skills) | https://github.com/anthropics/skills | `skills/skill-creator` |

## Setup after clone

```sh
git submodule update --init --recursive
```
