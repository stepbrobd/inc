{ inputs, lib, ... }:

{ config, ... }:

let
  inherit (lib) mkIf mkMerge;
  inherit (lib.blueprint.services.niks3) domain;
  hasTag = lib.hasTag config.networking.hostName;
  cfg = config.services.niks3;
in
{
  imports = [ inputs.niks3.nixosModules.default ];

  config = mkMerge [
    (mkIf (hasTag "niks3") {
      services.niks3.enable = lib.mkDefault true;
    })

    (mkIf cfg.enable {
      sops.secrets = {
        "niks3/s3-access-key".owner = cfg.user;
        "niks3/s3-secret-key".owner = cfg.user;
        "niks3/nix-signing-key".owner = cfg.user;
        "niks3/niks3-api-token".owner = cfg.user;
      };

      services.niks3 = {
        cacheUrl = "https://cache.ysun.co";

        httpAddr = "[::1]:5751";

        signKeyFiles = [ config.sops.secrets."niks3/nix-signing-key".path ];
        apiTokenFile = config.sops.secrets."niks3/niks3-api-token".path;

        s3 = let region = "us-east-005"; in {
          bucket = "stepbrobd";

          inherit region;
          endpoint = "s3.${region}.backblazeb2.com";
          useSSL = true;

          accessKeyFile = config.sops.secrets."niks3/s3-access-key".path;
          secretKeyFile = config.sops.secrets."niks3/s3-secret-key".path;
        };

        oidc.providers.github = {
          issuer = "https://token.actions.githubusercontent.com";
          audience = "https://${domain}";
          boundClaims.repository_owner = [ "stepbrobd" ];
        };
      };

      services.caddy = {
        enable = true;
        virtualHosts.${domain}.extraConfig = ''
          import common
          reverse_proxy ${cfg.httpAddr}
        '';
      };
    })
  ];
}
