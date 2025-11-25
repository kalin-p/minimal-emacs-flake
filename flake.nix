{
  description = "Provides emacs from a commit";

  inputs = {
    emacs = {
      url = "tarball+https://cgit.git.savannah.gnu.org/cgit/emacs.git/snapshot/emacs-30.2.tar.gz";
      flake = false;
    };
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    treesitter-grammars.url = "github:kalin-p/nix-treesitter";
  };

  outputs = { self, nixpkgs, emacs, treesitter-grammars }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
    in
      {
        packages.${system}.default = pkgs.stdenv.mkDerivation {
          pname = "kalins_emacs";
          version = "30.2";
          src = emacs;

          nativeBuildInputs = with pkgs; [
            autoconf
            pkg-config
            wrapGAppsHook3
            # libgccjit
            gcc
          ];

          buildInputs = with pkgs; [
            gnutls
            texinfo
            gtk3
            glib
            sqlite
            tree-sitter
            ncurses
            cairo
          ];

          # propagatedBuildInputs = [ treesitter-grammars.packages.${system}.default ];

          #               --with-native-compilation=aot\
          configurePhase = ''
            ./autogen.sh

            echo ${treesitter-grammars.packages.${system}.default}

            ./configure \
              --with-mailutils\
              --with-json\
              --with-tree-sitter\
              --with-pgtk\
              --program-prefix=kalins_\
              --prefix=$out
          '';

          buildPhase = ''
            make -j8
          '';

          installPhase = ''
            make install
          '';

          postInstall = ''
            # mkdir -p $out/lib/tree-sitter
            echo marker_kalin_1
            echo $out/lib/tree-sitter
            ln -s ${treesitter-grammars.packages.${system}.default} $out/lib/tree-sitter
            ls $out/lib/tree-sitter
          '';
        };
      };
}
