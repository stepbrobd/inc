{ lib, ... }:

let
  inherit (lib.terranix) forZone mkPersonalSiteRebind mkPurelyMailRecord;
in
{
  resource.cloudflare_dns_record = forZone "xdg.sh"
    {
      sh_xdg_apex = mkPersonalSiteRebind { name = "@"; };
    } // mkPurelyMailRecord
    "xdg.sh"
    "sh_xdg"
  ;
}
