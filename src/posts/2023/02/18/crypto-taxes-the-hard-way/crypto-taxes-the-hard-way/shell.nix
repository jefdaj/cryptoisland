let

  # Current system nixpkgs, not deterministic.
  pkgs = import <nixpkgs> {};

  # Pinned nixpkgs, deterministic.
  # TODO pick a more recent release hash from github before using
  # pkgs = import (fetchTarball("https://github.com/NixOS/nixpkgs/archive/a58a0b5098f0c2a389ee70eb69422a052982d990.tar.gz")) {};

  # Haskell compiler with packages needed for export/export.hs
  myGhc = pkgs.haskell.packages.ghc944.ghcWithPackages (ps: with ps; [
    shake
    directory
  ]);

in pkgs.mkShell {
  buildInputs = with pkgs; [
    hledger
    myGhc
  ];

  # Prevents frustrating encoding errors reading some csv files
  shellHook = ''
    export LOCALE_ARCHIVE="${pkgs.glibcLocales}/lib/locale/locale-archive"
  '';
}
