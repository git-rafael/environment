# AGENTS.md

This file provides guidance to AI agents when working with code in this repository. This repository is a personal Linux environment containing [Nix](https://nixos.org/) modules and resources for various targets and devices.

## Applying Environments

The central command is `env-load`, defined in [resources/scripts/env-load](resources/scripts/env-load) and packaged via [sources/utility.nix](sources/utility.nix).

```sh
# Apply a home-manager user environment (from this repo locally)
env-load user <target> ~/path/to/environment

# Apply and update flake inputs first
env-load user <target> ~/path/to/environment --update

# Apply a NixOS system configuration
env-load system <device> ~/path/to/environment

# Bootstrap a new NixOS device in the repo (prompts for hostname/features)
env-load system init ~/path/to/environment

# Enroll Secure Boot keys and TPM2 LUKS tokens (after system apply)
sudo env-load system enroll ~/path/to/environment

# Garbage collect (safe)
env-load clean

# Delete ALL generations and collect garbage (no rollback possible)
env-load purge
```

When `env-load` is not yet installed, use:
```sh
nix build 'github:git-rafael/environment#homeConfigurations.<target>.activationPackage' --no-link && \
  $(nix path-info 'github:git-rafael/environment#homeConfigurations.<target>.activationPackage')/activate
```

Before suggesting `env-load` for local changes in this repository, always suggest creating a local git commit first, because the user cannot apply those changes here without a commit.

## Architecture

### Two separate flakes

- **Root flake** ([flake.nix](flake.nix)): Home Manager configurations. Uses `nixpkgs/release-25.11` (stable) and `nixpkgs/nixos-unstable` (edge). Each device maps to a `homeConfigurations.<name>` output.
- **Devices flake** ([devices/flake.nix](devices/flake.nix)): NixOS system configurations. Lives in `devices/` with its own `flake.lock`. Each hostname maps to a `nixosConfigurations.<hostname>` output.

### Home Manager modules (sources/)

All modules are functions instantiated with an `env` attrset from [flake.nix](flake.nix), including `pkgs`, `edgePkgs`, `features`, `self`, and target metadata such as `username` when needed.

| File | Purpose |
|------|---------|
| [sources/agents.nix](sources/agents.nix) | pi, Claude Code, Codex, Ollama, agent-browser, herdr, pi settings, and shared skill exports |
| [sources/shell.nix](sources/shell.nix) | zsh, tmux, starship, direnv, broot, git, fonts, `env-shell` script |
| [sources/development.nix](sources/development.nix) | VSCodium (FHS), devbox, devenv, podman/docker, gh, quarto |
| [sources/utility.nix](sources/utility.nix) | `env-load`, chromium, bitwarden-cli, common CLI tools, `gtoken` script |
| [sources/operation.nix](sources/operation.nix) | Cloud/infra tools: AWS, k8s, helm, Kafka, Databricks, CircleCI, steampipe |
| [sources/security.nix](sources/security.nix) | Security tools: metasploit, nmap, tor, socat, sshuttle, gitleaks, etc. |

### Features system

Features are a list of strings passed per-device. Modules gate packages/config with:
- `withUI = builtins.elem "ui" features` — desktop/GUI apps (Plasma, Chromium, etc.)
- `forWork = builtins.elem "work" features` — work-specific tooling
- `forServers = builtins.elem "server" features` — server-only packages

Current devices and their features:
| Target | Features |
|--------|----------|
| `notebook` | `os`, `ui`, `work` |
| `tablet`, `portable` | `ui` |
| `corehub` | `server` |
| `phone` | _(none)_ |

The `os` feature sets `targets.genericLinux.enable = false`, meaning Home Manager integrates with NixOS instead of running standalone.

### NixOS system configurations (devices/)

Device-specific configs import shared modules:
- [devices/os.nix](devices/os.nix) — base OS: boot, networking, pipewire, virtualisation (docker, waydroid, libvirtd), nix-ld
- [devices/ui.nix](devices/ui.nix) — KDE Plasma 6 + SDDM, printing (CUPS/Epson), scanning (SANE)
- Per-device subfolder: `configuration.nix` (imports os.nix + ui.nix + hardware) and `hardware-configuration.nix`

New devices are bootstrapped with `env-load system init <path>`, which scaffolds the subfolder (copying `/etc/nixos/hardware-configuration.nix` and merging any LUKS entries from `/etc/nixos/configuration.nix`), injects the new `nixosConfigurations.<hostname>` entry into [devices/flake.nix](devices/flake.nix), and commits. The init prompts for Secure Boot (lanzaboote) and adds `crypttabExtraOpts` for TPM2 on all LUKS volumes when enabled.

#### Secure Boot and TPM2 enrollment

Devices with lanzaboote (Secure Boot) and/or TPM2-based LUKS auto-unlock require a one-time enrollment step after the first `env-load system <device>`:

```sh
sudo env-load system enroll ~/path/to/environment
```

This command:
1. **Secure Boot**: creates sbctl keys if missing, removes immutable EFI variable attributes, enrolls keys with `--microsoft --firmware-builtin`. Requires BIOS to be in Setup Mode (delete PK or enable Custom/Expert Key Management).
2. **TPM2 LUKS**: enrolls each LUKS volume from `hardware-configuration.nix` via `systemd-cryptenroll --tpm2-device=auto --tpm2-pcrs=0+7`. The original passphrase slot is preserved as fallback.

PCR choice: `0+7` (firmware + Secure Boot state) is the default. If a BIOS/UEFI update changes PCR 0, the TPM2 unlock falls back to the passphrase prompt — re-enroll with:
```sh
sudo systemd-cryptenroll --wipe-slot=tpm2 --tpm2-device=auto --tpm2-pcrs=0+7 /dev/disk/by-uuid/<uuid>
```

Current status: enabled on `AMININT-544228` (root + swap).

### Custom packages and scripts in resources/

Support resource files:
- Scripts embedded via `builtins.readFile`.
- Settings deployed via `home.file`.
- General files like binaries, certificates, images and so on.

### Agent skill sourcing

Third-party agent skills and extensions are declared through [resources/agents/pi/settings.json](resources/agents/pi/settings.json).

The current model is:

- pi installs upstream packages from the declarative `packages` list in `settings.json`
- non-standard upstream skill paths can be added through the `skills` list in `settings.json`
- [sources/agents.nix](sources/agents.nix) exports selected pi-managed skills from `~/.pi/agent/` into the shared `~/.agents/skills/` directory
- `~/.claude/skills`, `~/.codex/skills/user`, and `~/.gemini/skills` all point at that shared directory
- repo-local skills continue to live directly under [resources/agents/skills/](resources/agents/skills/)

This repo no longer uses `.refs/` submodules or `env-load refs` for skill management.

## Nix Packaging Notes

- Use `pkgs.lib.optionals withUI [...]` to guard GUI-only packages in `home.packages`.
- Use `pkgs.lib.optionals forWork [...]` to guard user work only packages in `home.packages`. Confirm with the user what is or isn't for work beforehand.
- `edgePkgs` (nixos-unstable) is available for packages that need a newer version than stable provides.
