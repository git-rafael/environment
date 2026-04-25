# AGENTS.md

Machine-level instructions for coding agents installed on this workstation.

## Communication

- Communicate in a friendly and concise manner.
- Be clear and helpful, avoiding unnecessary jargon or complexity.

## Commits

- After completing usable, non-intermediate changes or deliverables in any repository, always suggest creating a local git commit.
- Suggest a simple, direct commit message.
- Do not add co-authorship or `Co-authored-by` trailers.
- The user may handle pushing separately.

## Local Environment

- Assume the host system is `NixOS` unless the user says otherwise.
- Assume the desktop environment is KDE Plasma 6.
- The canonical local clone of this repository is `~/Desktop/Codebase/home/environment`.
- Verify the active repository path before running commands that depend on the canonical local clone path.

## Environment Repository

- When working with `~/Desktop/Codebase/home/environment`, read `~/Desktop/Codebase/home/environment/AGENTS.md` before making changes.
- Use that repository guidance to understand architecture, targets, and the supported apply workflow.
- Prefer `env-load user <target> ~/Desktop/Codebase/home/environment` or `env-load system <device> ~/Desktop/Codebase/home/environment` over raw `home-manager switch` or `nixos-rebuild switch`, unless the user explicitly asks otherwise.

## Tooling

- If a required tool is missing, prefer using `nix-shell` instead of assuming a global installation.

## Package Management

- Do not install packages persistently with `nix-env`, `nix profile`, `pip`, `npm`, or any other package manager directly on the machine, unless the user explicitly asks for that.
- You may use `nix-shell` for temporary tests or experiments when a tool is missing.
- If a tool or package should remain available for the user, suggest the corresponding change in `~/Desktop/Codebase/home/environment` so it becomes part of the versioned environment.
- When a persistent package change is needed, prefer updating the repository and applying it with `env-load user <target> ~/Desktop/Codebase/home/environment` or `env-load system <device> ~/Desktop/Codebase/home/environment`.

## Skills

- You may install or link skills locally for temporary agent testing when needed.
- Do not treat ad hoc local skill installation as the final persistent solution.
- For persistent skill availability, suggest adding the skill to `~/Desktop/Codebase/home/environment` using the repository conventions: pi package declarations in `resources/agents/pi/settings.json`, explicit skill path exports when needed, and repo-local skills under `resources/agents/skills`.
- Prefer persistent skill changes in the environment repository over manual one-off changes in agent home directories.

## Workarounds

- When using the `pi-herdr` extension, remember that `herdr run` submits a line plus Enter to the target pane; it does not guarantee that the pane is a shell.
- Before using `herdr run` for a shell command, confirm the target pane is actually a shell and not an already-running Pi/agent pane.
- If a herdr pane shows an agent such as Pi, treat `herdr run` input as a prompt/message to that agent, not as a shell command; do not send commands like `pi --no-session` into an existing Pi pane.
- Prefer `bash` for quick local shell commands, and use `herdr` for long-running processes only in panes that are confirmed to be shell panes.
- Prefer `pi-web-access` as the canonical `web_search` provider on this workstation.
- For checkpoint-driven/deep research loops, call `web_search` with `workflow: "none"` to avoid the interactive curator interrupting the loop.
- Use the `pi-web-access` parameter names: `numResults`, `domainFilter`, `recencyFilter`, `includeContent`, and `provider`.
- Do not use older Tavily/Brave-style `web_search` parameter names such as `max_results`, `search_depth`, `include_domains`, or `exclude_domains` unless the active tool schema explicitly supports them.
- When using `pi-deep-research`, combine `web_search` from `pi-web-access` with the available deep research tools such as `web_extract` and `research_checkpoint`.
