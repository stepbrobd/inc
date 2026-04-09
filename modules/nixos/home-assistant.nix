{ lib, ... }:

{ config, pkgs, ... }:

let
  cfg = config.services.home-assistant;
  hasTag = lib.hasTag config.networking.hostName;
  inherit (lib.blueprint.services.home-assistant) domain;
in
{
  config = lib.mkMerge [
    (lib.mkIf (hasTag "home-assistant") {
      services.home-assistant.enable = lib.mkDefault true;
    })
    (lib.mkIf config.services.home-assistant.enable {
      services.caddy.enable = true;

      services.home-assistant = {
        openFirewall = false;

        config.default_config = { };
        config.homeassistant.time_zone = null;

        config.http = {
          server_port = 8123;
          use_x_forwarded_for = true;
          trusted_proxies = [ "::1" ];
        };

        extraComponents = [
          "analytics"
          "apple_tv"
          "bluetooth"
          "cloud"
          "default_config"
          "google_translate"
          "homekit"
          "homekit_controller"
          "isal"
          "kegtron"
          "met"
          "nextdns"
          "shopping_list"
          "ssdp"
          "switchbot"
          "switchbot_cloud"
          "vesync"
          "zeroconf"
        ];

        customComponents = with pkgs.home-assistant-custom-components; [
          auth_oidc
          midea_ac_lan
          spook
          # gtfs-rt feeds for grenoble were previously served at data.metromobilite.fr but that domain has been decommed
          # the replacement api at data.mobilites-m.fr serves static gtfs data but does not expose gtfs-rt
          # realtime data is only available via proprietary json api:
          # - https://data.mobilites-m.fr/api/routers/default/index/clusters/{SEM:id}/stoptimes
          # - see: https://www.mobilites-m.fr/pages/opendata/OpenDataApi.html
          # - static feed: https://data.mobilites-m.fr/api/gtfs/SEM
          gtfs-realtime
        ];
      };

      networking.firewall = {
        allowedTCPPorts = [ 21064 ];
        allowedUDPPorts = [ 5353 ];
      };

      services.caddy.virtualHosts.${domain}.extraConfig = ''
        import common
        reverse_proxy [::1]:${lib.toString cfg.config.http.server_port}
      '';
    })
  ];
}
