# ABOUTME: Makes the Darwin Emacs.app start correctly without the emacsWithPackages shell wrapper.
# ABOUTME: Puts the real executable, the preloaded native-lisp files and the package paths inside the bundle.
{ python3 }:

# macOS records an app for login restore by the bundle that owns the *running*
# executable, not the bundle LaunchServices was asked to start. The stock
# `emacsWithPackages` app is a stub that execs the base Emacs in the store, so
# macOS restores that store bundle instead: no EMACSLOADPATH, no package
# `site-start`, no tree-sitter grammar directory, and an ad-hoc code identity
# that no TCC grant matches.
#
# Move the three things a start needs into the bundle itself, so every way of
# starting it behaves the same. Everything else stays in the store and is
# reached through `LSEnvironment`.
finalPackage:
finalPackage.overrideAttrs (old: {
  buildCommand = old.buildCommand + ''
    app="$out/Applications/Emacs.app"
    if [ -d "$app" ]; then
      # 1. The real Mach-O, in place of the wrapper stub. Its ad-hoc linker
      # signature covers the executable alone, so editing Info.plist below
      # does not invalidate it and no re-signing step is needed here.
      rm -f "$app/Contents/MacOS/Emacs" "$app/Contents/MacOS/.Emacs-wrapped"
      cp "$emacs/Applications/Emacs.app/Contents/MacOS/Emacs" "$app/Contents/MacOS/Emacs"
      chmod u+w "$app/Contents/MacOS/Emacs"
      # Its dump, which pdumper.c tries next to the executable first. The
      # fingerprinted dump in the base store path is not enough: another
      # machine can hold a different build of that same path, whose dump then
      # fails the fingerprint check and Emacs starts without one. Only the
      # mac port also ships it inside its app, so take the libexec copy that
      # both ports install.
      dumps=("$emacs"/libexec/emacs/*/*/emacs-*.pdmp)
      if [ "''${#dumps[@]}" -ne 1 ] || [ ! -f "''${dumps[0]}" ]; then
        echo "mac-bundle: expected one fingerprinted dump, found: ''${dumps[*]}" >&2
        exit 1
      fi
      cp "''${dumps[0]}" "$app/Contents/MacOS/Emacs.pdmp"

      # 2. The preloaded native-lisp files. pdumper.c resolves these relative
      # to the executable before Lisp runs and has no absolute fallback, so
      # they have to be real files in the bundle. A symlink would not do:
      # Home Manager's copyApps rsyncs with --copy-unsafe-links and would
      # materialise the whole native-lisp tree on every generation.
      for preloaded in "$emacs"/lib/emacs/*/native-lisp/*/preloaded; do
        abi="$(basename "$(dirname "$preloaded")")"
        mkdir -p "$app/Contents/native-lisp/$abi"
        cp -R "$preloaded" "$app/Contents/native-lisp/$abi/preloaded"
      done

      # 3. The package paths. LSEnvironment reaches every LaunchServices
      # start including the login restore, which is the case the shell
      # wrapper cannot cover. emacsWithPackages_invocationDirectory is
      # deliberately left out: the bundle is copied out of the store by Home
      # Manager, and invocation-directory is already right once the real
      # executable lives in the bundle.
      nativeLisp="$(echo "$emacs"/lib/emacs/*/native-lisp)"
      plist="$app/Contents/Info.plist"
      chmod u+w "$plist"
      ${python3}/bin/python3 ${./mac-bundle-env.py} \
        "$plist" \
        "$deps/share/emacs/site-lisp" \
        "$deps/share/emacs/native-lisp" \
        "$nativeLisp"
    fi
  '';
})
