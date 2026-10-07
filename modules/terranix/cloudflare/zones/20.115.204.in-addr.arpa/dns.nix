{ lib, ... }:

let
  inherit (lib.terranix) mkPurelyMailRecord mkRdnsWildcard;
  zone = "20.115.204.in-addr.arpa";
  prefix = "arpa_in_addr_204_115_20";
in
{
  resource.cloudflare_dns_record = mkPurelyMailRecord zone prefix // mkRdnsWildcard zone prefix;
}
