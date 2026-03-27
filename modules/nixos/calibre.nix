{ lib, ... }:

{ config, ... }:

let
  hasTag = lib.hasTag config.networking.hostName;
  inherit (lib.blueprint.services.calibre-web) domain;
in
{
  config = lib.mkMerge [
    (lib.mkIf (hasTag "calibre-web") {
      services.calibre-web.enable = lib.mkDefault true;
    })
    (lib.mkIf config.services.calibre-web.enable {
      services.calibre-web = {
        listen.ip = "::1";
        listen.port = 8083;

        options = {
          enableBookUploading = true;
          enableBookConversion = true;
          calibreLibrary = "/var/lib/calibre-web/books";
        };
      };

      services.caddy = {
        enable = true;
        virtualHosts.${domain}.extraConfig =
          with config.services.calibre-web.listen ;
          ''
            import common
            import csp
            reverse_proxy [${ip}]:${lib.toString port}
          '';
      };
    })
  ];
}
