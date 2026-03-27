{ inputs, lib, ... }:

{ config, options, pkgs, ... }:

let
  hasTag = lib.hasTag config.networking.hostName;
  ysun = inputs.ysun.packages.${pkgs.stdenv.hostPlatform.system}.default;
in
{
  config = lib.mkIf (hasTag "ysun") {
    # TODO: bind to ::1 when 0.0.17 bump is merged
    services.go-csp-collector = {
      enable = true;
      settings = {
        output-format = "json";
        log-client-ip = true;
        query-params-metadata = true;
        truncate-query-fragment = false;
        debug = false;
      };
    };

    services.caddy =
      let
        common = ''
          import common
          import csp
          header X-Served-By "${config.networking.fqdn}"
        '';

        arpa = ''
          ${config.services.caddy.virtualHosts."ysun.co".extraConfig}
        '';
      in
      {
        enable = true;
        virtualHosts."ysun.co" = {
          extraConfig = ''
            ${common}

            root * ${ysun}/var/www/html
            file_server

            @csp method POST && path /csp/*
            handle @csp {
              uri strip_prefix /csp/
              reverse_proxy [::1]:${lib.toString config.services.go-csp-collector.settings.port}
            }

            handle_errors {
              rewrite * /error
              file_server
            }
          '';
        };

        # dont redirect arpa zones
        # keep is this way in case i want to try out new CA
        # already tried lets encrypt, zerossl, ssl.com
        virtualHosts."http://0.0.9.5.f.2.0.6.2.ip6.arpa" = {
          logFormat = lib.mkForce config.services.caddy.virtualHosts."ysun.co".logFormat;
          extraConfig = arpa;
        };
        virtualHosts."http://104.161.23.in-addr.arpa" = {
          logFormat = lib.mkForce config.services.caddy.virtualHosts."ysun.co".logFormat;
          extraConfig = arpa;
        };
        virtualHosts."http://136.104.192.in-addr.arpa" = {
          logFormat = lib.mkForce config.services.caddy.virtualHosts."ysun.co".logFormat;
          extraConfig = arpa;
        };

        virtualHosts."*.ysun.co" = {
          logFormat = lib.mkForce config.services.caddy.virtualHosts."ysun.co".logFormat;
          extraConfig = ''
            ${common}
            redir https://ysun.co{uri} permanent
          '';
          serverAliases = [
            "as10779.net"
            "as18932.net"
            "churn.cards"
            "deeznuts.phd"
            "internal.center"
            "stepbrobd.com"
            "xdg.sh"
            "ysun.jp"
            "*.as10779.net"
            "*.as18932.net"
            "*.churn.cards"
            "*.deeznuts.phd"
            "*.internal.center"
            "*.stepbrobd.com"
            "*.xdg.sh"
            "*.ysun.jp"
          ];
        };
      };
  };
}
