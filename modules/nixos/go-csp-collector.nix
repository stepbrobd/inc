{ lib, ... }:

{ config, ... }:

let
  hasTag = lib.hasTag config.networking.hostName;
  inherit (lib.blueprint.services.go-csp-collector) domain;
in
{
  config = lib.mkIf (hasTag "csp") {
    services.go-csp-collector = {
      enable = true;

      settings = {
        port = 54321;
        output-format = "json";
        log-client-ip = true;
        query-params-metadata = true;
        truncate-query-fragment = false;
        debug = false;
        # ipv6 bind wont parse
        metrics-bind-addr = "127.0.0.1";
        metrics-port = "9090";
      };
    };

    services.victoriametrics.prometheusConfig.scrape_configs = lib.mkIf config.services.victoriametrics.enable [{
      job_name = "go-csp-collector";
      static_configs = [{
        targets = [ "${config.services.go-csp-collector.settings.metrics-bind-addr}:${config.services.go-csp-collector.settings.metrics-port}" ];
      }];
    }];

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
          request_body {
            max_size 1MB
          }
          reverse_proxy [::1]:${lib.toString config.services.go-csp-collector.settings.port}
        }

        handle {
          redir https://ysun.co/ permanent
        }
      '';
    };
  };
}
