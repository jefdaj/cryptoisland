{
  description = "cryptoisland.blog dev shell";
  inputs = {
    nixpkgs.url = github:NixOS/nixpkgs/nixos-unstable;
  };
  outputs = {self, nixpkgs}:
    let
      pkgs = import nixpkgs { system = "x86_64-linux"; };
    in rec {

      # The dev shell is the main output.
      # TODO unless you count the final static files?
      devShells."x86_64-linux".default =
        let
          myGhc = pkgs.haskellPackages.ghcWithPackages (ps: with ps; [
            # TODO which of these are really needed?
            bytestring
            hakyll
            hakyll-images
            hakyll-sass
            filepath
            pandoc
            MissingH
            hjsmin
            text
            language-javascript
            aeson
          ]);
        in
          pkgs.mkShell {
            buildInputs = with pkgs; [
              myGhc
              rsync
              graphviz
            ];
            shellHook = ''
              export LOCALE_ARCHIVE="${pkgs.glibcLocales}/lib/locale/locale-archive"
            '';
          };

      # Wrapper script that can be included as a package in a NixOS config.
      # Ensures that it'll work offline after a nixos-rebuild without fetching anything else.
      packages."x86_64-linux".wrapperScript = pkgs.writeScriptBin "cryptoisland-shell" ''
        #!/usr/bin/env bash
        export PATH=${pkgs.lib.makeBinPath devShells.x86_64-linux.default.buildInputs}:$PATH
        ${devShells.x86_64-linux.default.shellHook}
        ${pkgs.bashInteractive}/bin/bash $@
      '';

      packages."x86_64-linux".default = packages."x86_64-linux".wrapperScript;
    };
  }
