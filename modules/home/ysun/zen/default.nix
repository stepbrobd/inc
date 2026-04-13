{ inputs, lib, ... }:

{ pkgs, ... }:

{
  home.packages = [ inputs.zen.packages.${pkgs.stdenv.hostPlatform.system}.default ];

  xdg.mimeApps.defaultApplications = lib.optionalAttrs pkgs.stdenv.isLinux {
    "text/html" = [ "zen.desktop" ];
    "x-scheme-handler/http" = [ "zen.desktop" ];
    "x-scheme-handler/https" = [ "zen.desktop" ];
    "x-scheme-handler/about" = [ "zen.desktop" ];
    "x-scheme-handler/unknown" = [ "zen.desktop" ];
  };
}
