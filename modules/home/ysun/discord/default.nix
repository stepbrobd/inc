{ pkgs, ... }:

{
  programs.vesktop = {
    enable = pkgs.stdenv.isLinux;

    settings.splashBackground = "#2c2d32";
  };

  xdg.mimeApps.enable = pkgs.stdenv.isLinux;
  xdg.mimeApps.associations.added."x-scheme-handler/discord" = [ "vesktop.desktop" ];
  xdg.mimeApps.defaultApplications."x-scheme-handler/discord" = [ "vesktop.desktop" ];
}
