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
  version = "0-unstable-2026-10-19";
  src = fetchFromGitea {
    domain = "codeberg.org";
    owner = "liaowang11";
    repo = "emacs-reader";
    rev = "7a620903525a4b748e7ebedd8bc53c78c4bccbf6";
    hash = "sha256-wLDwpME/vi5seR7Tmq4BcFA96W6ci3JBQ4CNdCefKDI=";
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
