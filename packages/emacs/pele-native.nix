# ABOUTME: Builds the pele-native dynamic module from LuciusChen/pele.el for GUI Emacs.
# ABOUTME: Bundles upstream Pele and QuickJS with Core Text (Darwin) or Pango (Linux) text sizing.
{
  lib,
  stdenv,
  emacs,
  python3,
  pkg-config,
  pango,
  cairo,
  fontconfig,
  pele-src,
}:
let
  suffix = stdenv.hostPlatform.extensions.sharedLibrary;
  textBackend = if stdenv.hostPlatform.isDarwin then "coretext" else "pango";
in
stdenv.mkDerivation {
  pname = "pele-native";
  version = "0.0.1-unstable-2026-11-26";
  src = pele-src;

  nativeBuildInputs = [
    python3
  ]
  ++ lib.optionals stdenv.hostPlatform.isLinux [
    pkg-config
  ];

  buildInputs = [
    emacs
  ]
  ++ lib.optionals stdenv.hostPlatform.isLinux [
    pango
    cairo
    fontconfig
  ];

  makeFlags = [
    "EMACS=${emacs}/bin/emacs"
    "CC=${stdenv.cc.targetPrefix}cc"
    "PYTHON=${python3}/bin/python3"
    "EMACS_INCLUDE=${emacs}/include"
    "MODULE_SUFFIX=${suffix}"
    "TEXT_BACKEND=${textBackend}"
    "all"
  ];

  installPhase = ''
    runHook preInstall

    install -Dm444 -t "$out/share/emacs/site-lisp" "pele-native${suffix}"

    runHook postInstall
  '';

  passthru.packageRequires = [ ];

  meta = {
    description = "Emacs dynamic module wrapping Pele Mermaid renderer in QuickJS";
    homepage = "https://github.com/LuciusChen/pele.el";
    license = lib.licenses.mit;
    platforms = lib.platforms.darwin ++ lib.platforms.linux;
  };
}
