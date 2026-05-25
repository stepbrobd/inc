{ lib, ... }:

let
  inherit (lib.terranix) forZone mkPersonalSiteRebind mkPurelyMailRecord;
in
{
  resource.cloudflare_dns_record = forZone "internal.center"
    {
      center_internal_apex = mkPersonalSiteRebind { name = "@"; };
    } // mkPurelyMailRecord
    "internal.center"
    "center_internal"
  ;
}
