{ lib, ... }:

{ config, options, pkgs, ... }:

let
  inherit (lib) mkIf mkOption types;

  cfg = config.services.attic;
  hasTag = lib.hasTag config.networking.hostName;
in
{
  options.services.attic = {
    inherit (options.services.atticd) settings;

    enable = mkOption {
      default = false;
      description = "Whether to enable attic service";
      example = true;
      type = types.bool;
    };
  };

  config = lib.mkMerge [
    (mkIf (hasTag "attic") {
      services.attic.enable = lib.mkDefault true;
    })
    (mkIf cfg.enable {
      sops.secrets.atticd = {
        # owner = config.services.atticd.user;
        # group = config.services.atticd.group;
      };

      services.atticd = {
        inherit (cfg) enable;

        environmentFile = config.sops.secrets.atticd.path;

        settings = cfg.settings // {
          compression.type = "zstd";

          chunking = {
            nar-size-threshold = 1; # chunk all cause cloudflare upload limit
            min-size = 128 * 1024;
            avg-size = 256 * 1024;
            max-size = 512 * 1024;
          };

          garbage-collection = {
            interval = "24 hours";
            default-retention-period = "12 months";
          };

          storage = {
            type = "s3";
            region = "auto";
            bucket = "cache";
            endpoint = "https://6ff6fca6d9ffe9c77dd15a9095076b3b.r2.cloudflarestorage.com";
          };
        };
      };

      environment.systemPackages = with pkgs; [ attic-client attic-server ];
    })
  ];
}
