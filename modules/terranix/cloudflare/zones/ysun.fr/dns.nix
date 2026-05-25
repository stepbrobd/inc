{ lib, ... }:

let
  inherit (lib.terranix) forZone mkPersonalSiteRebind mkPurelyMailRecord;
in
{
  resource.cloudflare_dns_record = forZone "ysun.fr"
    {
      fr_ysun_apex = mkPersonalSiteRebind { name = "@"; };
    } // mkPurelyMailRecord
    "ysun.fr"
    "fr_ysun"
  ;
}
