{ lib, ... }:

{ config, pkgs, ... }:

let
  hasTag = lib.hasTag config.networking.hostName;
  inherit (lib.blueprint.services.stump) domain;

  cfg = config.services.stump;
in
{
  config = lib.mkMerge [
    (lib.mkIf (hasTag "stump") {
      services.stump.enable = lib.mkDefault true;
    })

    (lib.mkIf cfg.enable {
      sops.secrets."stump/oidc".owner = cfg.user;

      services.stump = {
        ip = "::1";
        secretFiles.STUMP_OIDC_CLIENT_SECRET = config.sops.secrets."stump/oidc".path;
        environment = {
          STUMP_CLIENT_DIR = "${pkgs.runCommand "client" { } ''
            cp -r ${cfg.package.frontend} $out
            chmod -R u+w $out
            rm -f $out/index.html.br $out/index.html.gz
            substituteInPlace $out/index.html --replace-fail '</head>' '<script defer data-domain="${domain}" src="https://${lib.blueprint.services.plausible.domain}/js/script.file-downloads.hash.outbound-links.js"></script></head>'
          ''}";
          STUMP_TRUST_PROXY_HEADERS = "true";
          STUMP_OIDC_ENABLED = "true";
          STUMP_OIDC_ISSUER_URL = "https://${lib.blueprint.services.kanidm.domain}/oauth2/openid/stump";
          STUMP_OIDC_CLIENT_ID = "stump";
          STUMP_OIDC_SCOPES = "openid email profile";
          STUMP_OIDC_ALLOW_REGISTRATION = "true";
          STUMP_OIDC_DISABLE_LOCAL_AUTH = "true";
        };
      };

      # the database holds the token signing secrets
      systemd.services.stump.serviceConfig = {
        StateDirectoryMode = "0750";
        UMask = "0027";
      };

      # library
      systemd.tmpfiles.rules = [
        "d '${cfg.configLocation}/books' 0750 ${cfg.user} ${cfg.group} - -"
      ];

      services.restic.backups.s3 = lib.mkIf (hasTag "backup") {
        paths = [ "${cfg.configLocation}/books" ];
        sqlite.stump = {
          path = "${cfg.configLocation}/stump.db";
          inherit (cfg) user;
        };
      };

      services.caddy = {
        enable = true;
        virtualHosts.${domain}.extraConfig = ''
          import reporting
          reverse_proxy [${cfg.ip}]:${lib.toString cfg.port}
        '';
      };
    })
  ];
}
