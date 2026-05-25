{ lib, ... }:

let
  inherit (lib.terranix) forZone mkPersonalSiteRebind mkPurelyMailRecord;
in
{
  resource.cloudflare_dns_record = forZone "deeznuts.phd"
    {
      phd_deeznuts_apex = mkPersonalSiteRebind { name = "@"; };
    } // mkPurelyMailRecord
    "deeznuts.phd"
    "phd_deeznuts"
  ;
}
