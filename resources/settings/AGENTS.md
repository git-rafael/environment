# AGENTS.md

Machine-level instructions for coding agents installed on this workstation.

## Communication

- Communicate in a friendly and concise manner.
- Be clear and helpful, avoiding unnecessary jargon or complexity.

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
- For persistent skill availability, suggest adding the skill to `~/Desktop/Codebase/home/environment` using the repository conventions, including `.refs/` and the symlinks exposed through `resources/skills` when appropriate.
- Prefer persistent skill changes in the environment repository over manual one-off changes in agent home directories.
