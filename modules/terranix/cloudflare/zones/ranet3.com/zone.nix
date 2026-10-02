{ lib, ... }:

let
  inherit (lib.terranix) mkZone mkZoneDnsSettings;
  zone = "ranet3.com";
in
{
  resource.cloudflare_zone.com_ranet3 = mkZone {
    name = zone;
  };

  resource.cloudflare_zone_dns_settings.com_ranet3_acns_settings = mkZoneDnsSettings zone;
}
