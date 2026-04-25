# npm package locks

This directory stores generated npm lockfiles for npm registry tarballs packaged from `sources/agents.nix` with `pkgs.buildNpmPackage`.

These files are generated artifacts, but they are intentionally versioned because nixpkgs' npm dependency fetcher requires a `package-lock.json` or `npm-shrinkwrap.json` to compute a stable `npmDepsHash`.

## Updating packages automatically

For local Home Manager applies, `env-load user <target> <repo> --update` refreshes every package listed in `packages.tsv` before running `nix flake update` and building the activation package.

The automation:

1. resolves the latest npm version;
2. prefetches the published npm tarball hash;
3. regenerates `package-lock.json` from the published tarball;
4. computes `npmDepsHash` with `nix run nixpkgs#prefetch-npm-deps`;
5. updates the matching package block in `sources/agents.nix`.

The repository must be clean before `env-load --update` starts. Commit the updated Nix files and lockfiles after reviewing the changes.

## Updating a package manually

1. Check the new npm version and tarball metadata, for example:

   ```sh
   npm view @evenrealities/even-terminal version dist.tarball dist.integrity --json
   ```

2. Update the package `version` and source tarball hash in `sources/agents.nix`.

3. Regenerate the lockfile from the published npm tarball, not from an arbitrary git checkout:

   ```sh
   tmp=$(mktemp -d)
   cd "$tmp"
   npm pack @evenrealities/even-terminal@<version> --ignore-scripts
   tar -xzf evenrealities-even-terminal-<version>.tgz
   cd package
   npm install --package-lock-only --ignore-scripts
   cp package-lock.json ~/Desktop/Codebase/home/environment/sources/.npm/packages/even-terminal/package-lock.json
   ```

4. Compute the dependency hash directly:

   ```sh
   nix run nixpkgs#prefetch-npm-deps -- sources/.npm/packages/even-terminal/package-lock.json
   ```

5. Update `npmDepsHash` in `sources/agents.nix` with the reported hash and rerun the build.

6. Commit `sources/agents.nix` and the lockfile together.

For packages whose published tarball already contains built output but whose `prepack` script tries to rebuild, keep `npmPackFlags = [ "--ignore-scripts" ];`.
