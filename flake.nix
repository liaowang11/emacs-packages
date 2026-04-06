{
  description = "Standalone Emacs final-package builds";

  nixConfig = {
    extra-substituters = [ "https://iosevka-wliao.cachix.org" ];
    extra-trusted-public-keys = [
      "iosevka-wliao.cachix.org-1:IJ+8jBJgx0SkMs2IA7V7XME5tdcVmpQSoL2JH1Bcy9E="
    ];
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    emacs-overlay = {
      url = "github:nix-community/emacs-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      emacs-overlay,
    }:
    let
      lib = nixpkgs.lib;
      supportedSystems = [
        "aarch64-darwin"
        "x86_64-linux"
      ];
      forAllSystems = lib.genAttrs supportedSystems;

      mkPkgs =
        system:
        import nixpkgs {
          inherit system;
          config.allowUnfree = true;
          overlays = [ emacs-overlay.overlay ];
        };

      mkBasePackages =
        pkgs:
        let
          icon = ./patches/Emacs.icns;
          pangoWithFontPatch = pkgs.pango.overrideAttrs (old: {
            patches = (old.patches or [ ]) ++ [
              (pkgs.fetchpatch {
                url = "https://gitlab.gnome.org/GNOME/pango/-/commit/4403954455f2b4a815b32e11c44f79b2e665e94c.diff";
                hash = "sha256-9HtPsBwqBR56YewDEbik1U1jakC7wTaCkKR+YXb9s4E=";
              })
            ];
          });
          librsvgWithPatchedPango = pkgs.librsvg.override {
            pango = pangoWithFontPatch;
          };
          emacsPlus =
            (pkgs.emacs30.override {
              librsvg = librsvgWithPatchedPango;
            }).overrideAttrs
              (old: {
                separateDebugInfo = true;
                passthru = (old.passthru or { }) // {
                  treeSitter = true;
                };
                patches = (old.patches or [ ]) ++ [
                  ./patches/fix-window-role.patch
                  ./patches/system-appearance.patch
                  ./patches/round-undecorated-frame.patch
                  ./patches/mac-font-use-typo-metrics.patch
                  ./patches/fix-macos-tahoe-scrolling.patch
                  ./patches/fix-ns-x-colors.patch
                ];
                postInstall = (old.postInstall or "") + ''
                  cp ${icon} $out/Applications/Emacs.app/Contents/Resources/Emacs.icns
                '';
              });
          emacsMac =
            (pkgs.emacs-macport.override {
              librsvg = librsvgWithPatchedPango;
            }).overrideAttrs
              (old: {
                configureFlags = old.configureFlags ++ [ "--with-xwidgets" ];
                patches = (old.patches or [ ]) ++ [
                  ./patches/emacs-mac-29.2-rc-1-multi-tty.diff
                  ./patches/emacs-macports30-undecorated-round.patch
                  ./patches/prefer-typo-ascender-descender-linegap.diff
                ];
                postInstall = (old.postInstall or "") + ''
                  cp ${icon} $out/Applications/Emacs.app/Contents/Resources/Emacs.icns
                '';
              });
        in
        {
          inherit emacsMac emacsPlus;
        };

      mkExtraPackages =
        pkgs: epkgs:
        let
          tdlibCompatible = pkgs.tdlib.overrideAttrs (old: {
            version = "1.8.61-11e254af6";
            postPatch = (old.postPatch or "") + ''
              substituteInPlace td/telegram/StarManager.cpp \
                --replace 'DialogId(UserId(G()->is_test_dc() ? 5001167034 : 8353936423))' \
                          'DialogId(UserId(static_cast<int64>(G()->is_test_dc() ? 5001167034 : 8353936423)))'
            '';
            src = pkgs.fetchFromGitHub {
              owner = "tdlib";
              repo = "td";
              rev = "11e254af6";
              sha256 = "03q6hr258ji5zk2c2i13d66rr8v64vzw7ia58xbzvxbicxm5xbw7";
            };
          });
          telegaPackage = epkgs.melpaPackages.telega.overrideAttrs (old: {
            version = "0.8.601";
            src = pkgs.fetchFromGitHub {
              owner = "zevlg";
              repo = "telega.el";
              rev = "d5a52a1a9f76cc4a4c601b48544d28afa8f55a80";
              sha256 = "0fpnbbaaffvicpi79qnmck6qrn3zf1ch37j8slw69blg5i3am1wz";
            };
            buildInputs = (lib.remove pkgs.tdlib old.buildInputs) ++ [ tdlibCompatible ];
            postPatch = (old.postPatch or "") + ''
              substituteInPlace telega-ffplay.el --replace '"ffmpeg -v quiet ' '"${pkgs.ffmpeg}/bin/ffmpeg -v quiet '
              substituteInPlace telega-ffplay.el --replace '(executable-find "ffplay")' '"${pkgs.ffmpeg}/bin/ffplay"'
              substituteInPlace telega-ffplay.el --replace '(executable-find "ffmpeg")' '"${pkgs.ffmpeg}/bin/ffmpeg"'
              substituteInPlace telega-ffplay.el --replace '"ffprobe -v error ' '"${pkgs.ffmpeg}/bin/ffprobe -v error '
              substituteInPlace telega-ffplay.el --replace '"ffmpeg -v 0 -i ' '"${pkgs.ffmpeg}/bin/ffmpeg -v 0 -i '
            '';
          });
          emacsReader = epkgs.callPackage ./packages/emacs/reader.nix { };
        in
        [
          epkgs.mu4e
          telegaPackage
        ]
        ++ [
          emacsReader
        ]
        ++ (with epkgs.melpaPackages; [
          vterm
          zmq
        ])
        ++ (with epkgs.manualPackages; [
          treesit-grammars.with-all-grammars
        ]);

      mkFinalPackage =
        system:
        { plus ? false, gui ? true }:
        let
          pkgs = mkPkgs system;
          basePackages = mkBasePackages pkgs;
          emacsPackage =
            if pkgs.stdenv.isDarwin then
              if plus then basePackages.emacsPlus else basePackages.emacsMac
            else if gui then
              pkgs.emacs-pgtk
            else
              pkgs.emacs-nox;
          epkgs = pkgs.emacsPackagesFor emacsPackage;
        in
        epkgs.emacsWithPackages (mkExtraPackages pkgs);

      mkPackages =
        system:
        let
          pkgs = mkPkgs system;
        in
        if pkgs.stdenv.isDarwin then
          {
            default = mkFinalPackage system { };
            macport = mkFinalPackage system { };
            plus = mkFinalPackage system { plus = true; };
          }
        else
          {
            default = mkFinalPackage system { };
            gui = mkFinalPackage system { };
            tty = mkFinalPackage system {
              gui = false;
            };
          };
    in
    {
      packages = forAllSystems mkPackages;

      checks = forAllSystems (
        system:
        let
          pkgs = mkPkgs system;
          packages = self.packages.${system};
        in
        {
          default =
            assert lib.hasInfix "with-packages" packages.default.name;
            pkgs.runCommand "emacs-final-package-check" { } "touch $out";
          variants =
            assert (
              if pkgs.stdenv.isDarwin then
                packages.default.drvPath != packages.plus.drvPath
              else
                packages.default.drvPath != packages.tty.drvPath
            );
            pkgs.runCommand "emacs-final-package-variant-check" { } "touch $out";
          update-workflow =
            assert import ./tests/update-workflow.nix;
            pkgs.runCommand "emacs-update-workflow-check" { } "touch $out";
        }
      );
    };
}
