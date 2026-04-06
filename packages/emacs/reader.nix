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
    owner = "MonadicSheep";
    repo = "emacs-reader";
    rev = "98c5046683e997902a83092b65cdb70ab120e000";
    hash = "sha256-Jo8ZecM4Y22T5kc5zJzCvSywkxwcpNEtQ3HHMJNesac=";
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
