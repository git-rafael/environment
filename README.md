# Personal Linux Environment

This is my personal Linux environment repository containing [Nix](https://nixos.org/) modules and resources for my devices.

## Structure

```
environment/
  sources/         # Nix modules (agents, development, shell, security, utility, operation)
  devices/         # NixOS system configurations per device
  resources/       # Scripts, settings, certificates and skills
```

## env-load

`env-load` is the central command for managing both Home Manager and NixOS configurations.

```sh
env-load user <target>             # apply a Nix user environment
env-load user <target> --update    # update flake inputs then apply
env-load system <device>           # apply a NixOS system environment
env-load system <device> --update  # update flake inputs then apply
env-load system init <path>        # bootstrap a new NixOS device in the repo
sudo env-load system enroll <path> # enroll Secure Boot keys and TPM2 LUKS tokens
```

### Home Manager

#### Available targets

| Target     | System        | User   | Features          |
|------------|---------------|--------|-------------------|
| `corehub`  | x86_64-linux  | root   | server            |
| `phone`    | aarch64-linux | —      | —                 |
| `tablet`   | x86_64-linux  | rafael | ui                |
| `portable` | x86_64-linux  | rafael | ui                |
| `notebook` | x86_64-linux  | rafael | os, ui, work      |

#### Bootstrap (first use)

```sh
curl -fsSL https://raw.githubusercontent.com/git-rafael/environment/main/resources/scripts/env-load | TARGET='<target>' sh
```

#### Update

```sh
env-load user <target>
```

Omitting the target reuses the last one saved in `~/.nix-target`.

#### env-shell

After loading, `env-shell` initializes the environment for interactive use (sources Nix profile and starts tmux). On NixOS devices, it drops straight into tmux.

### NixOS System Configuration

NixOS device configurations live in `devices/`. Each device has its own subfolder with `configuration.nix` and `hardware-configuration.nix`.

> **Note:** `hardware-configuration.nix` is hardware and partition-specific. If the device is reformatted or repartitioned, regenerate it and update the repo before applying the flake:
> ```sh
> nixos-generate-config --show-hardware-config > devices/<hostname>/hardware-configuration.nix
> ```

#### Fresh install

After the user environment is applied (via the bootstrap above), follow these steps:

**1. Clone the repo and initialize the device**

`system init` prompts for hostname, username, description and features (fingerprint, Secure Boot, TPM2, Cloudflare WARP, etc.), generates `devices/<hostname>/{configuration,hardware-configuration}.nix`, injects the new entry in `devices/flake.nix`, and commits. LUKS entries from `/etc/nixos/configuration.nix` are merged into the device's `hardware-configuration.nix` automatically.

```sh
git clone git@github.com:git-rafael/environment.git ~/Desktop/Codebase/environment
env-load system init ~/Desktop/Codebase/environment
```

**2. Review the generated files, then apply**

```sh
sudo env-load system <hostname> ~/Desktop/Codebase/environment
```

**3. Enroll Secure Boot and TPM2 (if enabled)**

For devices with Secure Boot (lanzaboote) and/or TPM2 LUKS auto-unlock, complete enrollment after applying:

```sh
sudo env-load system enroll ~/Desktop/Codebase/environment
```

This creates sbctl keys, removes immutable EFI variable attributes, enrolls Secure Boot keys (with Microsoft + firmware built-in keys), and enrolls TPM2 tokens for each LUKS volume. The BIOS must be in Setup Mode for Secure Boot enrollment — if not, the command will guide you through enabling it.

#### Applying updates

```sh
sudo env-load system <hostname>
```

## Platform Notes

### Termux

Termux requires a `proot` chroot environment before running `env-load`:

```sh
pkg upgrade -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" &&\
pkg install proot -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" &&\
\
unset LD_PRELOAD && termux-chroot "curl -fsSL https://raw.githubusercontent.com/git-rafael/environment/main/resources/scripts/env-load | TARGET='mobile' sh" &&\
\
echo '' > ${PREFIX}/etc/motd && \
echo 'unset LD_PRELOAD && exec termux-chroot "exec ${HOME}/.nix-profile/bin/env-shell"' > ${HOME}/.bashrc &&\
exit;
```

### ChromeOS (Crostini)

Some versions may need to unmount specific `/proc` paths before installing Nix:

```sh
sudo umount /proc/{cpuinfo,diskstats,meminfo,stat,uptime};
```

To have applications appear in the ChromeOS launcher, extend `cros-garcon` to include Nix paths:

```sh
mkdir -p ~/.config/systemd/user/cros-garcon.service.d/ &&\
cat > ~/.config/systemd/user/cros-garcon.service.d/override.conf <<EOF
[Service]
Environment="PATH=%h/.nix-profile/bin:/usr/local/sbin:/usr/local/bin:/usr/local/games:/usr/sbin:/usr/bin:/usr/games:/sbin:/bin"
Environment="XDG_DATA_DIRS=%h/.nix-profile/share:%h/.local/share:/usr/local/share:/usr/share"
EOF
```

Restart the container for changes to take place.

## Pi and Agent Skills

Pi is packaged declaratively in `sources/agents.nix` from a pinned npm release of `@mariozechner/pi-coding-agent`.

- The pinned npm dependency graph for the pi CLI lives in `resources/packages/pi/package-lock.json`
- Third-party pi packages, skills, and extensions are declared in `resources/agents/pi/settings.json`
- Upstream packages are declared in pi settings under `packages`
- Non-standard skill paths can be added through pi settings under `skills`
- `sources/agents.nix` exports selected pi-managed skills into `~/.agents/skills`
- Claude, Codex, and Gemini consume that shared `~/.agents/skills` directory
- Repo-local skills still live directly under `resources/agents/skills/`

## Notes

- The only dependency for the bootstrap script is `curl` and `sh`. Some minimal systems may need to install `curl` first via the OS package manager.
