# Personal Linux Environment

This is my personal Linux environment repository containing [Nix](https://nixos.org/) modules and resources for my devices.

## Loading

On first use:

```sh
curl -fsSL https://raw.githubusercontent.com/git-rafael/environment/main/resources/scripts/env-load | TARGET='<target>' sh
```

If loading a `device` type, the `target` environment and the `env-load` script will be available locally. To update with the latest version:

```sh
env-load '<target>'
```

Typically, you will update with the same `target` from first use, but it is possible to switch to another compatible `device` environment thanks to how [Nix](https://nixos.org/) works. The `env-shell` command will also be available to initialize the environment for usage.

## Targets

- **mobile**: loads on a device with [Termux](https://termux.dev/en) on a [Android](https://www.android.com/intl/en-US) system, contains tools for security, systems and data operations.
- **personal**: loads on a device with [Crostini](https://chromeos.dev/en/linux) on a [ChromeOS](https://chromeos.dev) system, contains tools for security, systems and data operations besides a data science and a systems development coding environment.
- **professional**: loads on a device with [Crostini](https://chromeos.dev/en/linux) on a [ChromeOS](https://chromeos.dev) system, contains tools for systems and data operations besides a data science and a systems development coding environment.
- **home**: loads on a device with [SSH & Web Terminal](https://github.com/hassio-addons/addon-ssh) on a [Home Assistant](https://www.home-assistant.io/) system, contains tools for security, systems and data operations besides a data science and a systems development environment.

## Notes

- Some systems may not come with `curl` installed, the only dependency for the bootstrap script besides `sh`. You will have to install `curl` yourself with the OS package manager or manually.

- Some versions of **ChromeOS** may need to [unmount specifc `/proc` paths](https://github.com/NixOS/nix/issues/4107) before installing [Nix](https://nixos.org/) on `crostini`:

```sh
sudo umount /proc/{cpuinfo,diskstats,meminfo,stat,uptime};
```

- The **Termux** environment needs a `chroot` environment set before starting `env-load`. The following snippet installs [PRoot](https://github.com/proot-me/proot) and configures the jailed startup to `env-shell`.

```sh
pkg upgrade -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" &&\
pkg install proot -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" &&\
\
unset LD_PRELOAD && termux-chroot "curl -fsSL https://raw.githubusercontent.com/git-rafael/environment/main/resources/scripts/env-load | TARGET='device.mobile' sh" &&\
\
echo '' > ${PREFIX}/etc/motd && \
echo 'unset LD_PRELOAD && exec termux-chroot "exec ${HOME}/.nix-profile/bin/env-shell"' > ${HOME}/.bashrc &&\
exit;
```
