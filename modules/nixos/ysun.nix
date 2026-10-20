# https://github.com/stepbrobd/ysun

{ inputs, lib, ... }:

{ config, pkgs, ... }:

let
  hasTag = lib.hasTag config.networking.hostName;
  ysun = inputs.ysun.packages.${pkgs.stdenv.hostPlatform.system}.default;
  etag = lib.head (lib.splitString "-" (baseNameOf ysun));

  canonical = "ysun.co";
  mirrors = [
    "deeznuts.phd"
    "internal.center"
    "stepbrobd.com"
    "xdg.sh"
    "ysun.fr"
    "ysun.jp"
    "ysun.us"
  ];
in
{
  config = lib.mkIf (hasTag "ysun") {
    services.caddy = {
      enable = true;

      virtualHosts = lib.genAttrs mirrors
        (_: {
          extraConfig = ''
            import base
            import reports
            redir https://${canonical}{uri} temporary
          '';
        }) // {
        ${canonical}.extraConfig = ''
          import webring

          @static path /assets/static/*
          @style  path /assets/style/*
          @pages   not path /assets/*

          header ETag `"${etag}"`
          header @static Cache-Control "public, max-age=604800"
          header @style  Cache-Control "public, max-age=300"
          header @pages   Cache-Control "public, no-cache"

          header X-Served-By "${config.networking.fqdn}"

          root * ${ysun}/var/www/html
          file_server

          handle_errors {
            root * ${ysun}/var/www/html
            header Cache-Control "public, no-cache"
            rewrite * /error
            file_server
          }
        '';
      };
    };
  };
}
