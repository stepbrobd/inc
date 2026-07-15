{ lib, ... }:

{ pkgs, ... }:

{
  home.packages = lib.optionals pkgs.stdenv.isLinux [
    pkgs.libreoffice-qt-fresh
    pkgs.hyphenDicts.en-us
    pkgs.hyphenDicts.fr-fr
  ];
}
