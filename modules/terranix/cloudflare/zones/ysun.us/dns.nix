{ lib, ... }:

let
  inherit (lib.terranix) forZone mkPersonalSiteRebind mkPurelyMailRecord;
in
{
  resource.cloudflare_dns_record = forZone "ysun.us"
    {
      us_ysun_apex = mkPersonalSiteRebind { name = "@"; };
    } // mkPurelyMailRecord
    "ysun.us"
    "us_ysun"
  ;
}
