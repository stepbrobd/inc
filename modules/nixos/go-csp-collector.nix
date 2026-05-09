{ lib, ... }:

{ config, ... }:

let
  hasTag = lib.hasTag config.networking.hostName;
  inherit (lib.blueprint.services.go-csp-collector) domain;
in
{
  config = lib.mkIf (hasTag "go-csp-collector") {
    services.go-csp-collector = {
      enable = true;

      settings = {
        port = 54321;
        output-format = "json";
        log-client-ip = true;
        query-params-metadata = true;
        truncate-query-fragment = false;
        debug = false;
      };
    };

    # TODO: add prometheus metrics exporting and scraping after 0.0.18 release

    services.caddy = {
      enable = true;

      virtualHosts.${domain}.extraConfig = ''
        import common

        @preflight method OPTIONS
        handle @preflight {
          header Access-Control-Allow-Origin {http.request.header.Origin}
          header Access-Control-Allow-Methods POST
          header Access-Control-Allow-Headers content-type
          header Access-Control-Max-Age 60
          header Vary Origin
          respond 204
        }

        @reports method POST
        handle @reports {
          reverse_proxy [::1]:${lib.toString config.services.go-csp-collector.settings.port}
        }

        redir https://ysun.co/ permanent
      '';
    };
  };
}
