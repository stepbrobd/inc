{ lib, ... }:

let
  inherit (lib.terranix) mkPurelyMailRecord mkRdnsWildcard;
  zone = "136.104.192.in-addr.arpa";
  prefix = "arpa_in_addr_192_104_136";
in
{
  resource.cloudflare_dns_record = mkPurelyMailRecord zone prefix // mkRdnsWildcard zone prefix;
}
