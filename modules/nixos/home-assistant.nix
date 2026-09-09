{ lib, ... }:

{ config, pkgs, ... }:

let
  hasTag = lib.hasTag config.networking.hostName;
  host = lib.blueprint.hosts.${config.networking.hostName};
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
        config.default_config = { };
        config.homeassistant.time_zone = null;

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
          "midea"
          "shopping_list"
          "ssdp"
          "switchbot"
          "switchbot_cloud"
          "vesync"
          "zeroconf"
        ];

        customComponents = with pkgs.home-assistant-custom-components; [
          auth_oidc
          spook
        ];
      };

      # recorder through the sqlite api and everything else as is
      services.restic.backups.s3 = with config.services.home-assistant; lib.mkIf (hasTag "backup") {
        paths = [ configDir ];
        # drop home assistant's own daily tarballs of the same state and gtfs_realtime feed archives
        exclude = lib.map (p: "${configDir}/${p}") [ "home-assistant_v2.db*" "home-assistant.log*" "backups" "deps" "tts" ".cache" ".storage/gtfs_realtime" ];
        sqlite.home-assistant = {
          path = "${configDir}/home-assistant_v2.db";
          user = "hass";
        };
      };

      # homekit bridge (21064) and mdns (5353) are lan only
      # but hass binds 0.0.0.0/[::]
      # have to restrict to local interface
      networking.firewall.interfaces.${host.interface} = {
        allowedTCPPorts = [ 21064 ];
        allowedUDPPorts = [ 5353 ];
      };

      services.caddy.virtualHosts.${domain}.extraConfig = ''
        import common
        import tailscale
        respond 404

        handle @tailnet {
          reverse_proxy [::1]:8123
        }
      '';
    })
  ];
}
