{ lib, ... }:

let
  inherit (lib.terranix) mkZone mkZoneDnsSettings;
  zone = "21.115.204.in-addr.arpa";
in
{
  resource.cloudflare_zone.arpa_in_addr_204_115_21 = mkZone {
    name = zone;
  };

  resource.cloudflare_zone_dns_settings.arpa_in_addr_204_115_21_acns_settings = mkZoneDnsSettings zone;
}
