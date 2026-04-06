{
  description = "Provides emacs from a commit";

  inputs = {
    emacs = {
      url = "tarball+https://cgit.git.savannah.gnu.org/cgit/emacs.git/snapshot/emacs-30.2.tar.gz";
      flake = false;
    };
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    treesitter-grammars.url = "github:kalin-p/nix-treesitter/39b550924b3a7f10885d8687a4a4b447976dfe3f";
  };

  outputs = { self, nixpkgs, emacs, treesitter-grammars }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      lib = pkgs.lib;

      grammars = treesitter-grammars.packages.${system}.default;

      libGccJitLibraryPaths = with pkgs; [
        "${lib.getLib libgccjit}/lib/gcc"
        "${lib.getLib stdenv.cc.libc}/lib"
      ]
      ++ lib.optionals (stdenv.cc ? cc.lib.libgcc) [
        "${lib.getLib stdenv.cc.cc.lib.libgcc}/lib"
      ];
    in
      # versions of the stdenv GCC and libgccjit from nixpkgs must be the same
      assert (pkgs.stdenv.cc.cc.version == pkgs.libgccjit.version);

      # TODO: look into whether a check should be put to determine if build
      # platform must be able to execute host platform or whatever they are
      # doing in the emacs package from nixpkgs
      {
        packages.${system}.default = pkgs.stdenv.mkDerivation {
          pname = "emacs";
          version = "30.2";
          src = emacs;

          nativeBuildInputs = with pkgs; [
            makeWrapper
            pkg-config
            autoreconfHook
            texinfo
            wrapGAppsHook3
          ];

          buildInputs = with pkgs; [
            gettext
            gnutls
            (lib.getDev harfbuzz)
            jansson
            ncurses
            dbus
            libselinux
            gsettings-desktop-schemas
            libgccjit
            zlib
            giflib
            gtk3
            libjpeg
            libpng
            librsvg
            libtiff
            gdk-pixbuf
            cairo
            glib
            sqlite
            systemd
            tree-sitter
          ];

          propagatedUserEnvPkgs = [
            pkgs.mailutils
          ];

          # correctly lists all grammars in the appropriate naming convention.
          # preConfigure = ''
          #   ls -lah ${grammars}
          # '';

          preFixupPhases = [ "addTreesitterLoc" ];


          addTreesitterLoc = ''
                gappsWrapperArgs+=(
                  --set KALINS_TREESITTER_GRAMMAR_LOCAION ${grammars}
                  --set LIBRARY_PATH ${lib.concatStringsSep ":" libGccJitLibraryPaths}
               )
            '';

          configureFlags = [

            "--with-pgtk"
            "--with-mailutils"
            "--with-json"
            "--with-tree-sitter"
            "--with-native-compilation=aot"
            # "--program-prefix=kalins_"
            "--verbose"
          ];

          env = {
            NATIVE_FULL_AOT = "1";
            LIBRARY_PATH = lib.concatStringsSep ":" libGccJitLibraryPaths;
          };

          enableParallelBuilding = true;

          # TODO: figure out what this does
          installTargets = [
            "tags"
            "install"
          ];

        };
      };
}
