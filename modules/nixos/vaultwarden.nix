{ lib, ... }:

{ config, ... }:

let
  cfg = config.services.vaultwarden;
  hasTag = lib.hasTag config.networking.hostName;
  inherit (lib.blueprint.services.vaultwarden) domain;
in
{
  config = lib.mkMerge [
    (lib.mkIf (hasTag "vaultwarden") {
      services.vaultwarden.enable = lib.mkDefault true;
    })
    (lib.mkIf cfg.enable {
      sops.secrets.vaultwarden = { };
      services.vaultwarden = {
        backupDir = "/var/backup/vaultwarden/";

        environmentFile = config.sops.secrets.vaultwarden.path;

        config = {
          DOMAIN = "https://${domain}";
          ROCKET_LOG = "critical";
          ROCKET_ADDRESS = "::1";
          ROCKET_PORT = 9999;
          SIGNUPS_ALLOWED = false;
          PASSWORD_HINTS_ALLOWED = false;
          SHOW_PASSWORD_HINT = false;
          ORG_EVENTS_ENABLED = true;
          SSO_ENABLED = true;
          SSO_PKCE = true;
          SSO_SCOPES = "openid email profile";
        };
      };

      services.caddy = {
        enable = true;

        # put headers here just in case
        # most likely i'll only be using this behind tailscale
        virtualHosts.${domain}.extraConfig = ''
          import common
          vars realip {remote_host}
          @cf header CF-Connecting-IP *
          vars @cf realip {header.CF-Connecting-IP}
          @xf header X-Forwarded-For *
          vars @xf realip {header.X-Forwarded-For}
          reverse_proxy [${lib.toString cfg.config.ROCKET_ADDRESS}]:${lib.toString cfg.config.ROCKET_PORT} {
            header_up X-Real-IP {vars.realip}
          }
        '';
      };

      services.fail2ban = {
        enable = true;

        jails = {
          vaultwarden-web = {
            filter = {
              INCLUDES.before = "common.conf";
              Definition = {
                failregex = "^.*Username or password is incorrect\. Try again\. IP: <ADDR>\. Username:.*$";
                ignoreregex = "";
              };
            };
            settings = {
              backend = "systemd";
              port = "80,443";
              filter = "vaultwarden-web[journalmatch='_SYSTEMD_UNIT=vaultwarden.service']";
              banaction = "%(banaction_allports)s";
              maxretry = 3;
              bantime = 14400;
              findtime = 14400;
            };
          };
          vaultwarden-admin = {
            filter = {
              INCLUDES.before = "common.conf";
              Definition = {
                failregex = "^.*Invalid admin token\. IP: <ADDR>.*$";
                ignoreregex = "";
              };
            };
            settings = {
              backend = "systemd";
              port = "80,443";
              filter = "vaultwarden-admin[journalmatch='_SYSTEMD_UNIT=vaultwarden.service']";
              banaction = "%(banaction_allports)s";
              maxretry = 3;
              bantime = 14400;
              findtime = 14400;
            };
          };
        };
      };
    })
  ];
}
