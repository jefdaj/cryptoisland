with import <nixpkgs> {};

let
  myGhc = pkgs.haskellPackages.ghcWithPackages (ps: with ps; [
    # TODO which of these are really needed?
    bytestring
    hakyll
    hakyll-images
    filepath
    pandoc
    MissingH
    hjsmin
    text
    language-javascript
    aeson
  ]);

in pkgs.mkShell {
  buildInputs = with pkgs; [
    myGhc
    rsync
  ];
  shellHook = ''
    export LOCALE_ARCHIVE="${pkgs.glibcLocales}/lib/locale/locale-archive"
  '';
}
