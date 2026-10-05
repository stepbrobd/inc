{ lib, ... }:

let
  inherit (lib.terranix) forZone mkPurelyMailRecord;
in
{
  resource.cloudflare_dns_record = forZone "gskr.ing"
    {
      ing_gskr_apex = {
        type = "CNAME";
        proxied = false;
        name = "@";
        content = "gskring.github.io";
        comment = "GitHub Pages";
      };

      ing_gskr_gh_verification = {
        type = "TXT";
        proxied = false;
        name = "_gh-gskring-o";
        content = ''"328ceb2796"'';
        comment = "GitHub Pages";
      };
    } // mkPurelyMailRecord
    "gskr.ing"
    "ing_gskr"
  ;
}
