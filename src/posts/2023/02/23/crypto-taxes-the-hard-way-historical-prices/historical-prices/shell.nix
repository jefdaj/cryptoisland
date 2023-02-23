let
  pkgs = import <nixpkgs> {};
  myR = pkgs.rWrapper.override {
    packages = with pkgs.rPackages; [
      tidyverse
    ];
  };

in pkgs.mkShell {
  buildInputs = with pkgs; [
    hledger
    myR
  ];

  # Prevents frustrating encoding errors reading some csv files
  shellHook = ''
    export LOCALE_ARCHIVE="${pkgs.glibcLocales}/lib/locale/locale-archive"
  '';
}
