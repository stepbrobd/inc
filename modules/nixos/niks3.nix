{ inputs, lib, ... }:

{ config, pkgs, ... }:

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
        package = pkgs.niks3;
        serverPackage = pkgs.niks3-server;

        cacheUrl = "https://cache.ysun.co";

        httpAddr = "[::1]:5751";

        gc.olderThan = "8760h";

        signKeyFiles = [ config.sops.secrets."niks3/nix-signing-key".path ];
        apiTokenFile = config.sops.secrets."niks3/niks3-api-token".path;

        # fastly object storage see modules/terranix/fastly/cache.nix
        s3 = let region = "us-east-1"; in {
          bucket = "cache";

          inherit region;
          endpoint = "${region}.object.fastlystorage.app";
          bucketLookup = "path";
          useSSL = true;

          accessKeyFile = config.sops.secrets."niks3/s3-access-key".path;
          secretKeyFile = config.sops.secrets."niks3/s3-secret-key".path;
        };

        oidc.providers.github = {
          issuer = "https://token.actions.githubusercontent.com";
          audience = "https://${domain}";
          boundClaims.repository = [
            "stepbrobd/*"
            "Filippo-Galli/Dotfiles"
          ];
        };
      };

      # closures are in cache bucket keep metadata backed up
      services.restic.backups.s3 = lib.mkIf (hasTag "backup") { postgresql = [ "niks3" ]; };

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
