{ lib, ... }:

let
  inherit (lib.terranix) mkPurelyMailRecord;
in
{
  resource.cloudflare_dns_record = mkPurelyMailRecord
    "20.115.204.in-addr.arpa"
    "arpa_in_addr_204_115_20"
  ;
}
