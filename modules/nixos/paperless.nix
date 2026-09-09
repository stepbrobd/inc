{ lib, ... }:

{ config, ... }:

let
  hasTag = lib.hasTag config.networking.hostName;
  inherit (lib.blueprint.services.paperless) domain;

  cfg = config.services.paperless;
in
{
  config = lib.mkMerge [
    (lib.mkIf (hasTag "paperless") {
      services.paperless.enable = lib.mkDefault true;
    })

    (lib.mkIf cfg.enable {
      sops.secrets."paperless/admin" = { };
      sops.secrets."paperless/oidc" = { };

      # allauth expects client secret inside json blob
      sops.templates."paperless.env".content = ''
        PAPERLESS_SOCIALACCOUNT_PROVIDERS='${lib.toJSON {
          openid_connect = {
            OAUTH_PKCE_ENABLED = true;
            APPS = [{
              provider_id = "kanidm";
              name = "Kanidm";
              client_id = "paperless";
              secret = config.sops.placeholder."paperless/oidc";
              settings = {
                server_url = "https://${lib.blueprint.services.kanidm.domain}/oauth2/openid/paperless/.well-known/openid-configuration";
                token_auth_method = "client_secret_basic";
              };
            }];
          };
        }}'
      '';

      services.paperless = {
        inherit domain;
        address = "::1";
        passwordFile = config.sops.secrets."paperless/admin".path;
        environmentFile = config.sops.templates."paperless.env".path;
        exporter.enable = true;

        settings = {
          PAPERLESS_ADMIN_USER = "ysun";
          PAPERLESS_ADMIN_MAIL = "ysun@hey.com";
          PAPERLESS_OCR_LANGUAGE = "eng+fra+jpn+chi_tra+chi_sim";
          PAPERLESS_APPS = "allauth.socialaccount.providers.openid_connect";
          PAPERLESS_ACCOUNT_ALLOW_SIGNUPS = false;
          PAPERLESS_SOCIALACCOUNT_ALLOW_SIGNUPS = true;
        };
      };

      services.caddy = {
        enable = true;

        # tailnet only
        virtualHosts.${domain}.extraConfig = ''
          import common
          import tailscale
          respond 404

          handle @tailnet {
            reverse_proxy [${cfg.address}]:${lib.toString cfg.port}
          }
        '';
      };
    })

    # exporter writes documents and metadata on its own timer
    # snapshot takes that rather than the live database and waits for an export in progress
    (lib.mkIf (cfg.enable && hasTag "backup") {
      services.restic.backups.s3.paths = [ cfg.exporter.directory ];
      systemd.services.restic-backups-s3.after = [ "paperless-exporter.service" ];
    })
  ];
}
