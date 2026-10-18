# emacs-packages

This repository builds standalone Emacs final packages and publishes successful builds to the `iosevka-wliao` Cachix cache.

## Package outputs

Darwin:

- `packages.aarch64-darwin.default`
- `packages.aarch64-darwin.macport`
- `packages.aarch64-darwin.plus`
- `packages.aarch64-darwin.client-app`
- `packages.aarch64-darwin.plus-client-app`
- `packages.aarch64-darwin.tramp-rpc-server`

Linux:

- `packages.aarch64-linux.default`
- `packages.aarch64-linux.gui`
- `packages.aarch64-linux.tty`
- `packages.x86_64-linux.default`
- `packages.x86_64-linux.gui`
- `packages.x86_64-linux.tty`
- `packages.<linux-system>.tramp-rpc-server`

## Darwin app bundle

On Darwin the final package post-processes `Applications/Emacs.app` in
`packages/emacs/mac-bundle.nix` so the app starts correctly on its own:

- the real Emacs executable replaces the `emacsWithPackages` wrapper stub,
  and its `Emacs.pdmp` dump sits beside it so the two always come from the
  same build;
- the preloaded `native-lisp` files are copied to `Contents/native-lisp`,
  where the dumper looks for them relative to the executable;
- the package paths go into the `Info.plist` `LSEnvironment` dict.

macOS records an app for login restore by the bundle that owns the running
executable. With the stock wrapper that is the base Emacs in the store, so a
restored Emacs came up with no package load path, no tree-sitter grammars and
an unrecognised code identity. The Linux packages keep the stock wrapper.

`checks.aarch64-darwin.darwin-bundle` starts the built bundle from a copy
outside the store, once with an empty environment and once with only the
`LSEnvironment` values, the way a login restore does.

## GitHub Actions

Both workflows run only when dispatched manually. The build workflow in `.github/workflows/build.yml` builds:

- `aarch64-darwin.default` and `aarch64-darwin.client-app`
- `aarch64-darwin.plus` and `aarch64-darwin.plus-client-app`
- `aarch64-linux.default`
- `aarch64-linux.tty`
- `x86_64-linux.default`
- `x86_64-linux.tty`

Manual runs push successful builds to `iosevka-wliao`.

The update workflow in `.github/workflows/update-flake-inputs.yml` updates flake inputs, commits `flake.lock` when it changes, and rebuilds all exported variants.

## Required Secret

Add this repository secret before enabling cache pushes:

- `CACHIX_AUTH_TOKEN`: write token for the `iosevka-wliao` cache

## Local Usage

```bash
nix build .#packages.aarch64-darwin.default
```
