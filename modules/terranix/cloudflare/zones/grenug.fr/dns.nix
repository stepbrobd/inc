{ lib, ... }:

let
  inherit (lib.terranix) forZone mkPurelyMailRecord;
in
{
  resource.cloudflare_dns_record = forZone "grenug.fr"
    {
      fr_grenug_wildcard = {
        type = "CNAME";
        proxied = true;
        name = "*";
        content = "grenug.fr";
        comment = "Cloudflare Workers - Grenuble Nix User Group";
      };

      fr_grenug_atproto = {
        type = "TXT";
        proxied = false;
        name = "_atproto";
        content = ''"did=did:plc:2avqf3fyabzocrmygamzdenj"'';
        comment = "Bluesky - Domain Verification";
      };
    } // mkPurelyMailRecord
    "grenug.fr"
    "fr_grenug"
  ;
}
