# Personal Linux Environment

This is my personal Linux environment repository containing [Nix](https://nixos.org/) modules, derivations and scripts for my various device classes and development containers.

## Loading

On first use:

```sh
curl -fsSL https://raw.githubusercontent.com/git-rafael/environment/main/resources/scripts/env-load | TARGET='<target>' sh
```

If loading a `device` type, the `target` environment and the `env-load` script will be available locally. To update with the latest version:

```sh
env-load '<target>'
```

Typically, you will update with the same `target` from the first use, but it is possible to switch to another compatible `device` environment thanks to how [Nix](https://nixos.org/) works.

After loading a `device` environment to your appliance other `targets` will be easily available with the `env-load` command, for example the [docker](https://www.docker.com/) based `containers`.

## Targets

### Containers

- **container.python**: dev container for [Python](https://www.python.org/) stacks and projects.
- **container.javascript**: dev container for [javascript](https://www.javascript.com/) stacks and projects.
- **container.java**: dev container for [Java](https://www.java.com/) stacks and projects.
- **container.dotnet**: dev container for [.NET Core](https://dotnet.microsoft.com/) stacks and projects.

### Devices

- **device.mobile**: loads on a device with [nix-on-droid](https://github.com/t184256/nix-on-droid), contains tools for systems and data operations.
- **device.personal**: loads on a device with [crostini](https://chromeos.dev/en/linux), contains tools for security, systems and data operations besides a science and development coding environment.
- **device.professional**: loads on a device with [crostini](https://chromeos.dev/en/linux), contains tools for systems and data operations besides a science and development coding environment.
- **device.home**: loads on a device with [SSH & Web Terminal](https://github.com/hassio-addons/addon-ssh) [Home Assistant](https://www.home-assistant.io/) addon, contains tools for security, systems and data operations besides a science and development environment.

## Notes

- Some systems may not come with `curl` installed, the only dependency for the bootstrap script besides `sh`. You will have to install `curl` yourself with the OS package manager or manually. For example, on [nix-on-droid](https://github.com/t184256/nix-on-droid) you can install `curl` with high priority:

```sh
nix-env -i curl;
nix-env --set-flag priority 0 curl;
```

- Some versions of ChromeOS may need to [unmount specifc `/proc` paths](https://github.com/NixOS/nix/issues/4107) before installing [Nix](https://nixos.org/) on `crostini`:

```sh
sudo umount /proc/{cpuinfo,diskstats,meminfo,stat,uptime};
```
