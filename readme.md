# Personal Linux Environment

This is my personal Linux environment repository containing [Nix](https://nixos.org/) modules, derivations and scripts for my various device classes and development containers.

## Loading

On first use:

```sh
curl -fsSL https://raw.githubusercontent.com/git-rafael/environment/main/scripts/env-load | TARGET='<target>' sh
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
- **container.node**: dev container for [Node.js](https://nodejs.org/) stacks and projects.
- **container.java**: dev container for [Java](https://www.java.com/) stacks and projects.
- **container.dotnet**: dev container for [.NET Core](https://dotnet.microsoft.com/) stacks and projects.
- **container.automation**: tools container for security, infrastructure operations and home automation.
- **container.laboratory**: tools container for data exploration, science and visualization.

### Devices

- **device.phone**: loads on a [nix-on-droid](https://github.com/t184256/nix-on-droid) environment, contains tools for quick infrastructure and security operations.
- **device.tablet**: loads on a default [crostini](https://chromeos.dev/en/linux) environment, contains some gaming and a light operations and development environment.
- **device.notebook**: loads on a default [crostini](https://chromeos.dev/en/linux) environment, contains a complete environment of development, security and operations tools.

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
