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
