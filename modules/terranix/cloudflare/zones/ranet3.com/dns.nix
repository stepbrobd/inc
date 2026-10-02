{ lib, ... }:

let
  inherit (lib.terranix) mkPurelyMailRecord;
in
{
  resource.cloudflare_dns_record = mkPurelyMailRecord "ranet3.com" "com_ranet3";
}
