# ABOUTME: Ensures the Darwin final package keeps the self-starting Emacs.app bundle layout.
# ABOUTME: Guards the login-restore fix, which has no cheap runtime check outside macOS.
{ lib }:
let
  flakeText = builtins.readFile ../flake.nix;
  bundleText = builtins.readFile ../packages/emacs/mac-bundle.nix;
  envScript = builtins.readFile ../packages/emacs/mac-bundle-env.py;
  bundleCheck = builtins.readFile ../tests/darwin-bundle.sh;

  assertHas =
    needle: text:
    lib.asserts.assertMsg (lib.hasInfix needle text) ''
      Expected to find:
        ${needle}
    '';

  assertLacks =
    needle: text:
    lib.asserts.assertMsg (!lib.hasInfix needle text) ''
      Expected not to find:
        ${needle}
    '';

  checks = [
    # Darwin only: the Linux packages keep the stock wrapper.
    (assertHas "macBundle = pkgs.callPackage ./packages/emacs/mac-bundle.nix { };" flakeText)
    (assertHas "if pkgs.stdenv.hostPlatform.isDarwin then macBundle withPackages else withPackages;" flakeText)

    # The real executable replaces the stub, so macOS restores this bundle.
    (assertHas ''rm -f "$app/Contents/MacOS/Emacs" "$app/Contents/MacOS/.Emacs-wrapped"'' bundleText)
    (assertHas ''cp "$emacs/Applications/Emacs.app/Contents/MacOS/Emacs" "$app/Contents/MacOS/Emacs"'' bundleText)
    # Its dump comes along, so the two always share a fingerprint.
    # Taken from libexec: the emacs-plus app has no Emacs.pdmp of its own.
    (assertHas ''dumps=("$emacs"/libexec/emacs/*/*/emacs-*.pdmp)'' bundleText)
    (assertHas "cp \"''\${dumps[0]}\" \"$app/Contents/MacOS/Emacs.pdmp\"" bundleText)
    (assertLacks ''cp "$emacs/Applications/Emacs.app/Contents/MacOS/Emacs.pdmp"'' bundleText)

    # Preloaded .eln must be real files: pdumper resolves them relative to the
    # executable, and the copyApps rsync follows symlinks that leave the tree.
    (assertHas ''cp -R "$preloaded" "$app/Contents/native-lisp/$abi/preloaded"'' bundleText)
    (assertLacks "ln -s" bundleText)

    # Paths ride in LSEnvironment, which is what a login restore reads.
    (assertHas ''"EMACSLOADPATH": site_lisp + ":"'' envScript)
    (assertHas ''"EMACSNATIVELOADPATH": deps_native_lisp + ":" + emacs_native_lisp + ":"'' envScript)
    (assertHas ''"emacsWithPackages_siteLisp": site_lisp'' envScript)
    (assertHas ''"emacsWithPackages_siteLispNative": deps_native_lisp'' envScript)
    # Baking the store invocation directory in would survive the copy to
    # ~/Applications and point Emacs back at the store.
    (assertLacks "emacsWithPackages_invocationDirectory" envScript)

    # The runtime check has to keep exercising a copy outside the store.
    (assertHas ''cp -R "$app" "$target/Emacs.app"'' bundleCheck)
    (assertHas ''target="$work/Home Manager Apps"'' bundleCheck)
    (assertHas "Copied bundle startup passed" bundleCheck)
  ];
in
builtins.foldl' (acc: check: builtins.seq acc check) true checks
