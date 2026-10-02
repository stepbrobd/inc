{ lib, ... }:

let
  inherit (lib.terranix) forZone mkAcnsRecord mkPersonalSiteRebind mkPurelyMailRecord;
in
{
  resource.cloudflare_dns_record = forZone "ysun.jp"
    {
      jp_ysun_apex = mkPersonalSiteRebind { name = "@"; };
    } // mkAcnsRecord "ysun.jp" "jp_ysun"
  // mkPurelyMailRecord
    "ysun.jp"
    "jp_ysun"
  ;
}
