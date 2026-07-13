# From: https://github.com/amusingimpala75/.dotfiles/blob/master/packages/emacs-packages/reader/package.nix
{
  fetchFromGitea,
  lib,
  melpaBuild,
  stdenv,
  emacs,
  pkg-config,
  mupdf-headless,
  ...
}:
let
  version = "0-unstable-2026-04-01";
  src = fetchFromGitea {
    domain = "codeberg.org";
    owner = "liaowang11";
    repo = "emacs-reader";
    rev = "d7ef09a15f389d5da9ac1130b7b479315edc0b3e";
    hash = "sha256-ah2S4gC9ZuTUtdTTUav2GCmGncmIlP73kQrdK4DPdyU=";
  };
  core = stdenv.mkDerivation {
    inherit src;
    name = "emacs-reader-core";
    buildFlags = [ "CC=cc" ];
    nativeBuildInputs = [ pkg-config ];
    buildInputs = [
      mupdf-headless
      emacs
    ];
    installPhase = ''
      runHook preInstall

      install -Dm444 -t $out/lib/ render-core${stdenv.targetPlatform.extensions.sharedLibrary}

      runHook postInstall
    '';
    # Necessary on darwin (tries to use homebrew over nix for some reason)
    patches = [ ./0001-remove-pkg-config-disabling-block-just-always-use-it.patch ];
  };
in
melpaBuild {
  pname = "reader";
  inherit src version;
  files = ''(:defaults "${lib.getLib core}/lib/render-core.*")'';
}
