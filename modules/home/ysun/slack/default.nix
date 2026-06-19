{ lib, ... }:

{ pkgs, ... }:

{
  home.packages = lib.mkIf pkgs.stdenv.isLinux [ pkgs.slack ];

  xdg.mimeApps.enable = pkgs.stdenv.isLinux;
  xdg.mimeApps.associations.added."x-scheme-handler/slack" = [ "slack.desktop" ];
  xdg.mimeApps.defaultApplications."x-scheme-handler/slack" = [ "slack.desktop" ];
}
