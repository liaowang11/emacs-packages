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
  version = "0-unstable-2026-09-12";
  src = fetchFromGitea {
    domain = "codeberg.org";
    owner = "liaowang11";
    repo = "emacs-reader";
    rev = "815fa14020584fa6d165d4f1941062f3456c9d23";
    hash = "sha256-T7Hek6Zivd8B+jfmQE1mTu7TU7kDnMdcTxN4V2bGWDQ=";
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
