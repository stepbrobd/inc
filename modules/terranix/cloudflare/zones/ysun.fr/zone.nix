{ lib, ... }:

let
  inherit (lib.terranix) mkZone mkZoneSettings;
  zone = "ysun.fr";
in
{
  resource.cloudflare_zone.fr_ysun = mkZone {
    name = zone;
  };

  resource.cloudflare_zone_dns_settings.fr_ysun_acns_settings = mkZoneSettings zone;
}
