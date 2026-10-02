{ lib, ... }:

let
  inherit (lib.terranix) forZone mkAcnsRecord mkPersonalSiteRebind mkPurelyMailRecord;
in
{
  resource.cloudflare_dns_record = forZone "ysun.us"
    {
      us_ysun_apex = mkPersonalSiteRebind { name = "@"; };
    } // mkAcnsRecord "ysun.us" "us_ysun"
  // mkPurelyMailRecord
    "ysun.us"
    "us_ysun"
  ;
}
