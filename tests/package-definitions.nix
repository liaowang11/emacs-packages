# ABOUTME: Ensures the standalone flake keeps the pinned Emacs package customizations and Darwin client app script.
# ABOUTME: Guards the moved packaging logic now that the main repo consumes this flake as an input.
{ lib }:
let
  flakeText = builtins.readFile ../flake.nix;
  createEmacsClientApp = builtins.readFile ../create-emacs-client-app.sh;

  assertHas =
    needle: text:
    lib.asserts.assertMsg (lib.hasInfix needle text) ''
      Expected to find:
        ${needle}
    '';

  checks = [
    (assertHas "telegaPackage = epkgs.melpaPackages.telega.overrideAttrs" flakeText)
    (assertHas "tdlibCompatible = pkgs.tdlib.overrideAttrs" flakeText)
    (assertHas "rev = \"11e254af6\"" flakeText)
    (assertHas "buildInputs = (lib.remove pkgs.tdlib old.buildInputs) ++ [ tdlibCompatible ];" flakeText)
    (assertHas "version = \"1.8.61-11e254af6\"" flakeText)
    (assertHas "version = \"0.8.601\"" flakeText)
    (assertHas "rev = \"d5a52a1a9f76cc4a4c601b48544d28afa8f55a80\"" flakeText)
    (assertHas "substituteInPlace td/telegram/StarManager.cpp" flakeText)
    (assertHas "substituteInPlace telega-ffplay.el" flakeText)
    (assertHas "executable-find \"ffplay\"" flakeText)
    (assertHas "executable-find \"ffmpeg\"" flakeText)
    (assertHas "ffprobe -v error " flakeText)
    (assertHas "/usr/bin/osacompile" createEmacsClientApp)
    (assertHas "Emacs Client.app" createEmacsClientApp)
    (assertHas "org-protocol" createEmacsClientApp)
  ];
in
builtins.foldl' (acc: check: builtins.seq acc check) true checks
