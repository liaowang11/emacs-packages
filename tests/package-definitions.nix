# ABOUTME: Ensures the standalone flake keeps the pinned Emacs package customizations and Darwin client app script.
# ABOUTME: Guards the moved packaging logic now that the main repo consumes this flake as an input.
{ lib }:
let
  flakeText = builtins.readFile ../flake.nix;
  createEmacsClientApp = builtins.readFile ../create-emacs-client-app.sh;
  treeSitterAbiPatch = builtins.readFile ../patches/emacs-mac-tree-sitter-abi-version.patch;

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
    (assertHas "telegaPackage = epkgs.melpaPackages.telega.overrideAttrs" flakeText)
    (assertHas "telega-src = {" flakeText)
    (assertHas "url = \"github:liaowang11/telega.el\";" flakeText)
    (assertHas "flake = false;" flakeText)
    (assertHas "src = telega-src;" flakeText)
    (assertLacks "version = \"0.8.602\";" flakeText)
    (assertLacks "version = \"1.8.61-11e254af6\"" flakeText)
    (assertLacks "rev = \"11e254af6\"" flakeText)
    (assertLacks "tdlibCompatible = pkgs.tdlib;" flakeText)
    (assertLacks "buildInputs = (lib.remove pkgs.tdlib old.buildInputs) ++ [ tdlibCompatible ];" flakeText)
    (assertLacks "substituteInPlace td/telegram/StarManager.cpp" flakeText)
    (assertHas "substituteInPlace telega-ffplay.el" flakeText)
    (assertHas "executable-find \"ffplay\"" flakeText)
    (assertHas "executable-find \"ffmpeg\"" flakeText)
    (assertHas "ffprobe -v error " flakeText)
    (assertHas "./patches/emacs-mac-tree-sitter-abi-version.patch" flakeText)
    (assertHas "ts_language_abi_version" treeSitterAbiPatch)
    (assertHas "/usr/bin/osacompile" createEmacsClientApp)
    (assertHas "Emacs Client.app" createEmacsClientApp)
    (assertHas "org-protocol" createEmacsClientApp)
  ];
in
builtins.foldl' (acc: check: builtins.seq acc check) true checks
