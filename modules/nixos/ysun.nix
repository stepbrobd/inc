{ inputs, lib, ... }:

{ config, pkgs, ... }:

let
  hasTag = lib.hasTag config.networking.hostName;
  ysun = inputs.ysun.packages.${pkgs.stdenv.hostPlatform.system}.default;
in
{
  config = lib.mkIf (hasTag "ysun") {
    services.caddy = {
      enable = true;

      virtualHosts."ysun.co" = {
        extraConfig = ''
          import common
          import reporting

          header X-Served-By "${config.networking.fqdn}"

          root * ${ysun}/var/www/html
          file_server

          handle_errors {
            rewrite * /error
            file_server
          }
        '';

        serverAliases = [
          "as10779.net"
          "as18932.net"
          "churn.cards"
          "deeznuts.phd"
          "internal.center"
          "stepbrobd.com"
          "xdg.sh"
          "ysun.fr"
          "ysun.jp"
          "ysun.us"
          # browser ca forum forbids rdns certs now fuckkkkkkkk
          "http://0.0.9.5.f.2.0.6.2.ip6.arpa"
          "http://104.161.23.in-addr.arpa"
          "http://136.104.192.in-addr.arpa"
        ];
      };
    };
  };
}
