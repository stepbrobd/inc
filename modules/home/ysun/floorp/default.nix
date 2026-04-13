{ lib, ... }:

{ pkgs, ... }:

{
  home.packages = [ pkgs.floorp-bin ];

  xdg.mimeApps.defaultApplications = lib.optionalAttrs pkgs.stdenv.isLinux {
    # "text/html" = [ "floorp.desktop" ];
    # "x-scheme-handler/http" = [ "floorp.desktop" ];
    # "x-scheme-handler/https" = [ "floorp.desktop" ];
    # "x-scheme-handler/about" = [ "floorp.desktop" ];
    # "x-scheme-handler/unknown" = [ "floorp.desktop" ];
  };
}
