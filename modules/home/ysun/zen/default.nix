{ inputs, lib, ... }:

{ pkgs, ... }:

{
  home.packages = [ inputs.zen.packages.${pkgs.stdenv.hostPlatform.system}.twilight ];

  home.sessionVariables = lib.optionalAttrs pkgs.stdenv.isLinux { BROWSER = "zen-twilight"; };

  xdg.mimeApps.enable = pkgs.stdenv.isLinux;
  xdg.mimeApps.defaultApplications = lib.optionalAttrs pkgs.stdenv.isLinux (
    lib.genAttrs [
      "text/html"
      "text/xml"
      "application/xml"
      "application/json"
      "application/xhtml+xml"
      "application/x-extension-htm"
      "application/x-extension-html"
      "application/x-extension-shtml"
      "application/x-extension-xht"
      "application/x-extension-xhtml"
      "application/pdf"
      "application/x-pdf"
      "image/svg+xml"
      "x-scheme-handler/http"
      "x-scheme-handler/https"
      "x-scheme-handler/about"
      "x-scheme-handler/unknown"
    ]
      (_: [ "zen-twilight.desktop" ])
  );
}
