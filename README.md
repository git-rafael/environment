# Personal Linux Environment

This is my personal Linux environment repository containing [Nix](https://nixos.org/) modules and resources for my devices.

## Structure

```
environment/
  sources/         # Nix modules (development, shell, security, utility, operation)
  devices/         # NixOS system configurations per device
  resources/       # Scripts, settings, certificates and skills
```

## env-load

`env-load` is the central command for managing both Home Manager and NixOS configurations.

```sh
env-load user <target>           # apply a Nix user environment
env-load user <target> --update  # update flake inputs then apply
env-load system <device>         # apply a NixOS system environment
env-load system <device> --update  # update flake inputs then apply
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

On first boot, flakes need to be enabled explicitly:

```sh
sudo nixos-rebuild switch \
  --flake github:git-rafael/environment?dir=devices#<hostname> \
  --experimental-features "nix-command flakes"
```

#### Applying updates

```sh
env-load system <hostname>
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

## External References (.refs/)

`.refs/` holds git submodules organized as `.refs/<org>/<repo>/` with sparse-checkout. Symlinks in `resources/` expose selected paths without duplicating files.

Managed via `env-load refs` (no Nix required):

```sh
env-load refs list                                     # list tracked refs and symlinks
env-load refs sync                                     # pull latest from all upstreams
env-load refs add anthropic/skills skills/mcp-builder  # add a path from a ref
env-load refs rm mcp-builder                           # remove a symlink
```

After cloning, initialize submodules with:

```sh
git submodule update --init --recursive
```

## Notes

- The only dependency for the bootstrap script is `curl` and `sh`. Some minimal systems may need to install `curl` first via the OS package manager.
