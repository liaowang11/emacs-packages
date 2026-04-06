# emacs-packages

This repository builds standalone Emacs final packages and publishes successful builds to the `iosevka-wliao` Cachix cache.

## Package outputs

Darwin:

- `packages.aarch64-darwin.default`
- `packages.aarch64-darwin.macport`
- `packages.aarch64-darwin.plus`

Linux:

- `packages.x86_64-linux.default`
- `packages.x86_64-linux.gui`
- `packages.x86_64-linux.tty`

## GitHub Actions

The build workflow in `.github/workflows/build.yml` builds:

- `aarch64-darwin.default`
- `aarch64-darwin.plus`
- `x86_64-linux.default`
- `x86_64-linux.tty`

Pull requests build without pushing to Cachix. Pushes to `main` and manual runs push successful builds to `iosevka-wliao`.

The update workflow in `.github/workflows/update-flake-inputs.yml` runs every Friday at `03:00 UTC`, updates flake inputs, commits `flake.lock` when it changes, and rebuilds all exported variants.

## Required Secret

Add this repository secret before enabling cache pushes:

- `CACHIX_AUTH_TOKEN`: write token for the `iosevka-wliao` cache

## Local Usage

```bash
nix build .#packages.aarch64-darwin.default
```
