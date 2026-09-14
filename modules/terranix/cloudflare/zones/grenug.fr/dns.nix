{ lib, ... }:

let
  inherit (lib.terranix) forZone mkPurelyMailRecord;
in
{
  resource.cloudflare_dns_record = forZone "grenug.fr"
    {
      fr_grenug_apex = {
        type = "CNAME";
        proxied = false;
        name = "@";
        content = "gre-nug.github.io";
        comment = "GitHub Pages";
      };

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

      fr_grenug_gh_verification = {
        type = "TXT";
        proxied = false;
        name = "_github-pages-challenge-gre-nug";
        content = ''"caa832b25d5ae0e50e2b0819b91ab4"'';
        comment = "GitHub Pages";
      };
    } // mkPurelyMailRecord
    "grenug.fr"
    "fr_grenug"
  ;
}
