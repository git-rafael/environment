---
name: environment-change
description: Update the persistent Nix environment for this workstation through `~/Desktop/Codebase/home/environment`. Use this skill whenever the user wants to add or remove packages permanently, change Home Manager or NixOS settings, add a persistent agent skill, adjust the notebook target or `AMININT-544228` host, or make a machine-level change "the Nix way" instead of using ad hoc local installs. Also use it for Portuguese requests like "instale isso de forma persistente", "adicione no Home Manager", "mude a configuração NixOS dessa máquina", "coloque essa skill no repo environment" or "faça isso via Nix".
compatibility:
  tools: [read, bash, edit, write]
---

# Environment Change

Manage persistent changes for this machine through the environment repository at `~/Desktop/Codebase/home/environment`.

Use this skill for repository-backed machine changes, not for throwaway experiments. If the user only needs a temporary tool for the current session, prefer a temporary approach instead of editing the environment repo.

## What this skill should do

Translate requests like these into the right repository change:

- "install this package permanently"
- "adjust my Home Manager"
- "change the NixOS config for this notebook"
- "make this available to Claude/Codex/Gemini on this machine"
- "add a persistent skill"
- "update the workstation setup"

The goal is to keep the machine reproducible. Prefer a versioned repo change over one-off mutation of the live system.

## Related skills

Use this skill for **persisting the result in the environment repo**.

- If the user wants to **create or iterate on a new skill itself**, use `skill-creator` for the drafting and evaluation loop, then place the final skill in `resources/agents/skills/` here.
- If the user wants to **discover an existing marketplace skill**, use `skill-finder` first, then use this skill to wire the chosen skill into pi's declarative settings persistently.

## First steps

1. Verify the canonical repository path exists: `~/Desktop/Codebase/home/environment`.
2. Read `~/Desktop/Codebase/home/environment/AGENTS.md` before planning edits.
3. Inspect the current repo state with `git status --short`.
4. Classify the request before editing anything:
   - **Home Manager package/config**
   - **NixOS system config**
   - **Local skill in this repo**
   - **Pi-managed upstream skill/package**
   - **Mixed change**
5. Identify the apply target for this machine:
   - Home Manager target: `notebook`
   - NixOS host: `AMININT-544228`

If the request is ambiguous between persistent and temporary, ask once before editing.

## Repository map

### Home Manager flake

Use the root `flake.nix` for user environments.

For this workstation:
- output: `homeConfigurations.notebook`
- username: `rafaeloliveira`
- features: `os`, `ui`, `work`

The main Home Manager modules live in `sources/`:

- `sources/agents.nix` — pi packaged from a pinned npm release, other agent CLIs from nixpkgs/edge nixpkgs, pi settings, and global agent instructions for Claude/Codex/Gemini/OpenCode
- `sources/shell.nix` — shell, tmux, git, fonts, `env-shell`
- `sources/development.nix` — editor and development tooling
- `sources/utility.nix` — common CLI tools, browser, agent CLIs, small utilities
- `sources/operation.nix` — cloud, kubernetes, infra tooling
- `sources/security.nix` — security tooling

### NixOS flake

Use `devices/flake.nix` for system changes.

For this workstation:
- output: `nixosConfigurations."AMININT-544228"`
- host folder: `devices/AMININT-544228/`

Shared system modules:
- `devices/os.nix` — boot, networking, audio, virtualization, users
- `devices/ui.nix` — Plasma, SDDM, printing, scanning
- `devices/options.nix` — custom per-device options

Host-specific overrides live in `devices/AMININT-544228/configuration.nix` and hardware data in `devices/AMININT-544228/hardware-configuration.nix`.

### Skills

Pi is the primary agent for declarative third-party skills and extensions in this repository.

That means:
- pi-managed upstream skills are declared in `resources/agents/pi/settings.json`
- non-standard pi skill paths can be added through the `skills` array in that settings file
- Claude Code, Codex, Gemini, and OpenCode keep their own native skill directories by default
- this repo shares the global `AGENTS.md` instruction file across agents, but does not create cross-agent skill links

Even a pi skill/package change usually ends with a Home Manager apply on this workstation.

## Decision rules

### 1) Installing or removing a persistent package

Choose the module by intent:

- shell/editor/session tooling → `sources/shell.nix`
- developer tools, editor runtimes, containers → `sources/development.nix`
- general CLI apps, browsers, agent CLIs → `sources/utility.nix`
- cloud/ops/platform tooling → `sources/operation.nix`
- offensive/defensive/security tooling → `sources/security.nix`

When editing package lists:
- Use `pkgs.lib.optionals withUI [...]` for GUI-only apps.
- Use `pkgs.lib.optionals forWork [...]` for work-only tools.
- Ask before placing something behind the `work` feature if the work/personal boundary is unclear.
- Keep `pi` on the pinned npm-tarball package pattern already used in `sources/agents.nix` unless explicitly asked otherwise.
- Prefer stable `pkgs` packages for other agent CLIs when they provide the required features.
- Use `edgePkgs` for other agent CLIs when stable `pkgs` is missing the package or lacks required agent features.
- Do not add custom non-pi agent CLI builds when a standard `pkgs` or `edgePkgs` package is available.

Do **not** solve persistent package requests with `nix-env`, `nix profile`, `pip install`, `npm install -g`, or similar one-off installs unless the user explicitly asks for that.

### 2) Changing Home Manager behavior

Edit the smallest relevant module in `sources/`.

Common examples:
- shell aliases, zsh, tmux → `sources/shell.nix`
- agent home files and pi settings → `sources/agents.nix`
- chromium or CLI utilities → `sources/utility.nix`
- VSCodium/dev tooling → `sources/development.nix`

If a new script is needed and it should be part of the environment, add it under `resources/scripts/` and package it from the appropriate module.

If a new settings file is needed, place it under `resources/settings/` and link it with `home.file` from the appropriate module.

### 3) Changing NixOS behavior

Use the shared module when the change is generic across machines; use the host folder when it is specific to `AMININT-544228`.

Examples:
- bootloader, sound, virtualisation, user groups → `devices/os.nix`
- Plasma, display manager, printers, scanners → `devices/ui.nix`
- hostname-specific services, certificates, secure boot toggles → `devices/AMININT-544228/configuration.nix`
- disk/LUKS/hardware-generated values → `devices/AMININT-544228/hardware-configuration.nix`

Be conservative with `hardware-configuration.nix`. Only edit it when the request is clearly about hardware- or partition-specific configuration.

### 4) Adding or changing a persistent skill

For a local skill maintained in this repo:
1. If the request is about inventing or refining the skill behavior itself, use `skill-creator` as the authoring workflow.
2. Create or edit `resources/agents/skills/<skill-name>/SKILL.md` only when the skill is intentionally maintained as repository content.
3. Add optional supporting files under that skill directory.
4. Keep the skill self-contained and explicit about when it should trigger.
5. Wire it to a specific agent only when explicitly requested; do not add cross-agent skill links by default.

For an upstream pi skill:
1. If the user still needs help choosing the skill, use `skill-finder` first.
2. Verify the real path to the skill inside the upstream repository.
3. Add or update the upstream package declaration in `resources/agents/pi/settings.json` under `packages`.
4. If the repo does not expose the skill through standard package discovery, add an explicit entry under the `skills` array in `resources/agents/pi/settings.json`.
5. Do not assume the marketplace `id` equals the repo path; verify the actual path containing `SKILL.md`.

## Validation workflow

After edits, propose the narrowest useful validation.

### Home Manager changes

From `~/Desktop/Codebase/home/environment`:

```bash
nix build '.#homeConfigurations.notebook.activationPackage'
```

### NixOS changes

From `~/Desktop/Codebase/home/environment/devices`:

```bash
nix build '.#nixosConfigurations."AMININT-544228".config.system.build.toplevel'
```

### Skill-only changes

At minimum:
- read the new `SKILL.md` back for a sanity check
- optionally add `evals/evals.json` if you are iterating on the skill
- if the user wants, run a small qualitative test loop next

If a change touches both Home Manager and NixOS, suggest validating both relevant outputs.

## Common commands

Use these when they directly help the task.

### Manage pi-declared upstream skills

Update these files when you need to persist a third-party skill:

```bash
resources/agents/pi/settings.json
sources/agents.nix
```

### Fallback when `env-load` is not installed yet

If `env-load` is unavailable locally but the user still needs to apply the Home Manager environment from this repo, use the documented activation fallback:

```bash
nix build '.#homeConfigurations.notebook.activationPackage' --no-link && \
  $(nix path-info '.#homeConfigurations.notebook.activationPackage')/activate
```

Use this as a fallback, not the default path.

## Apply workflow

Prefer the repository's standard apply commands.

### Important constraint

`env-load` refuses to apply a dirty repository. Before suggesting a local apply for changes in this repo, remind the user to create a local git commit first.

### Apply commands for this machine

Home Manager:

```bash
env-load user notebook ~/Desktop/Codebase/home/environment
```

NixOS:

```bash
sudo env-load system AMININT-544228 ~/Desktop/Codebase/home/environment
```

If the user explicitly asks to update flake inputs too, use `--update`.

Prefer these commands over raw `home-manager switch` or `nixos-rebuild switch` unless the user explicitly asks otherwise.

## Expected response format

When you finish a task using this skill, give the user a short actionable summary with this structure:

### Summary
- what changed
- whether it affects Home Manager, NixOS, skills, or more than one

### Files changed
- list each touched path with a short reason

### Validation
- commands already run, or the commands you recommend running next

### Apply
- exact `env-load` command(s) for this machine
- explicitly note that a local commit is needed before apply if the repo is still dirty

### Commit suggestion
- suggest a short imperative English commit message

## Guardrails

- Prefer small, targeted edits over broad rewrites.
- Read the relevant files before changing them.
- Preserve repository conventions and feature gates.
- Do not install persistent software outside the repo unless the user explicitly asks.
- Do not suggest `env-load` for local uncommitted changes without reminding the user to commit first.
- If the user asks for a machine change but the correct target is unclear, confirm whether the change is for `notebook`, `AMININT-544228`, or another target.
- If the request is only for a temporary experiment, say so and avoid turning it into a persistent environment change by default.

## Examples

**Example 1**
Input: "Install `fd` permanently on this notebook."
Output approach: update the appropriate `sources/*.nix` module, validate `homeConfigurations.notebook`, then suggest `env-load user notebook ~/Desktop/Codebase/home/environment` after a local commit.

**Example 2**
Input: "Add a persistent skill for Claude Code and Codex on this machine."
Output approach: for Pi, update `resources/agents/pi/settings.json` when the skill comes from an upstream package, or add it under `resources/agents/skills/` only when it is intentionally repo-local. Explain that skills are not shared across agents by default, then suggest applying the Home Manager environment after a local commit.

**Example 3**
Input: "Enable a system-level service only on `AMININT-544228`."
Output approach: edit the host-specific file under `devices/AMININT-544228/`, validate the NixOS build, then suggest `sudo env-load system AMININT-544228 ~/Desktop/Codebase/home/environment` after a local commit.
