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
unset LD_PRELOAD && termux-chroot "curl -fsSL https://raw.githubusercontent.com/git-rafael/environment/main/resources/scripts/env-load | TARGET='mobile' sh" &&\
\
echo '' > ${PREFIX}/etc/motd && \
echo 'unset LD_PRELOAD && exec termux-chroot "exec ${HOME}/.nix-profile/bin/env-shell"' > ${HOME}/.bashrc &&\
exit;
```

- To have applications within **Chrome OS** launcher, `crostini` expects *.desktop* files to be dropped under *$XDG_DATA*. Applications are registered using a service running within the container called `cros-garcon`, and as it is a simple systemd service you can easily extend it to look in nix-specific locations (restart the container for changes to take place).

```sh
mkdir -p ~/.config/systemd/user/cros-garcon.service.d/ &&\
cat > ~/.config/systemd/user/cros-garcon.service.d/override.conf <<EOF
[Service]
Environment="PATH=%h/.nix-profile/bin:/usr/local/sbin:/usr/local/bin:/usr/local/games:/usr/sbin:/usr/bin:/usr/games:/sbin:/bin"
Environment="XDG_DATA_DIRS=%h/.nix-profile/share:%h/.local/share:/usr/local/share:/usr/share"
EOF
```
