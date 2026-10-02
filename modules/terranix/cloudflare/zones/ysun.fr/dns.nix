{ lib, ... }:

let
  inherit (lib.terranix) forZone mkAcnsRecord mkPersonalSiteRebind mkPurelyMailRecord;
in
{
  resource.cloudflare_dns_record = forZone "ysun.fr"
    {
      fr_ysun_apex = mkPersonalSiteRebind { name = "@"; };
    } // mkAcnsRecord "ysun.fr" "fr_ysun"
  // mkPurelyMailRecord
    "ysun.fr"
    "fr_ysun"
  ;
}
