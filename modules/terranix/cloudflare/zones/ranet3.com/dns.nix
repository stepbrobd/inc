{ lib, ... }:

let
  inherit (lib.terranix) forZone mkPurelyMailRecord;
in
{
  resource.cloudflare_dns_record = forZone "ranet3.com"
    {
      com_ranet3_apex = {
        type = "CNAME";
        proxied = false;
        name = "@";
        content = "ranet3.github.io";
        comment = "GitHub Pages";
      };

      com_ranet3_www = {
        type = "CNAME";
        proxied = false;
        name = "www";
        content = "ranet3.github.io";
        comment = "GitHub Pages";
      };

      com_ranet3_gh_verification = {
        type = "TXT";
        proxied = false;
        name = "_github-pages-challenge-ranet3";
        content = ''"d67eca4c8b6abb6092041077e59464"'';
        comment = "GitHub Pages";
      };

      com_ranet3_google = {
        type = "TXT";
        proxied = false;
        name = "@";
        content = ''"google-site-verification=gG9sn5HAM4UwdwHUn3T9L1nAQv2bkv8QvVpi6cW8Am8"'';
        comment = "Google - Search Console";
      };
    } // mkPurelyMailRecord
    "ranet3.com"
    "com_ranet3"
  ;
}
