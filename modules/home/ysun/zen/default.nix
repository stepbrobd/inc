{ inputs, lib, ... }:

{ pkgs, ... }:

{
  home.packages = [ inputs.zen.packages.${pkgs.stdenv.hostPlatform.system}.default ];

  xdg.mimeApps.defaultApplications = lib.optionalAttrs pkgs.stdenv.isLinux (
    lib.genAttrs [
      "text/html"
      "application/xhtml+xml"
      "application/x-extension-htm"
      "application/x-extension-html"
      "application/x-extension-shtml"
      "application/x-extension-xht"
      "application/x-extension-xhtml"
      "application/pdf"
      "application/x-pdf"
      "x-scheme-handler/http"
      "x-scheme-handler/https"
      "x-scheme-handler/about"
      "x-scheme-handler/unknown"
    ]
      (_: [ "zen.desktop" ])
  );
}
