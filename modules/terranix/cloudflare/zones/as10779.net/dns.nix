{ lib, ... }:

let
  inherit (lib.terranix) forZone mkPersonalSiteRebind mkPurelyMailRecord;
in
{
  resource.cloudflare_dns_record = forZone "as10779.net"
    {
      net_as10779_apex = mkPersonalSiteRebind { name = "@"; };
    } // mkPurelyMailRecord
    "as10779.net"
    "net_as10779"
  ;
}
