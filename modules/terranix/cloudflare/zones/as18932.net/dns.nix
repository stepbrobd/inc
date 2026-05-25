{ lib, ... }:

let
  inherit (lib.terranix) forZone mkPersonalSiteRebind mkPurelyMailRecord;
in
{
  resource.cloudflare_dns_record = forZone "as18932.net"
    {
      net_as18932_apex = mkPersonalSiteRebind { name = "@"; };
    } // mkPurelyMailRecord
    "as18932.net"
    "net_as18932"
  ;
}
