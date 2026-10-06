{ lib, ... }:

let
  inherit (lib.terranix) forZone mkPurelyMailRecord;
in
{
  resource.cloudflare_dns_record = forZone "ranet3.com"
    {
      com_ranet3_gh_verification = {
        type = "TXT";
        proxied = false;
        name = "_github-pages-challenge-ranet3";
        content = ''"d67eca4c8b6abb6092041077e59464"'';
        comment = "GitHub Pages";
      };
    } // mkPurelyMailRecord
    "ranet3.com"
    "com_ranet3"
  ;
}
