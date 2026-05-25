{ lib, ... }:

let
  inherit (lib.terranix) forZone mkPersonalSiteRebind mkPurelyMailRecord;
in
{
  resource.cloudflare_dns_record = forZone "stepbrobd.com"
    {
      com_stepbrobd_apex = mkPersonalSiteRebind { name = "@"; };

      com_stepbrobd_atproto = {
        type = "TXT";
        proxied = false;
        name = "_atproto";
        content = ''"did=did:plc:y7e726xl4qjoubevqiccgc4q"'';
        comment = "Bluesky - Domain Verification";
      };

      com_stepbrobd_discord = {
        type = "TXT";
        proxied = false;
        name = "_discord";
        content = ''"dh=e9440c4b087ef618d1ad72ee0b2cd6dc64f90b6e"'';
        comment = "Discord - Verification";
      };

      com_stepbrobd_openai = {
        type = "TXT";
        proxied = false;
        name = "@";
        content = ''"openai-domain-verification=dv-JvUlthuUbYFfiymxstPINpHg"'';
        comment = "OpenAI - Domain Verification";
      };

      com_stepbrobd_tailscale = {
        type = "TXT";
        proxied = false;
        name = "@";
        content = ''"TAILSCALE-n5eugndxcV9xFXlLFOpC"'';
        comment = "Tailscale - Verification";
      };

      com_stepbrobd_twilio = {
        type = "TXT";
        proxied = false;
        name = "_twilio";
        content = ''"twilio-domain-verification=f46e7a05c199fb36f91438cc6d2fabee"'';
        comment = "Twilio - Verification";
      };
    } // mkPurelyMailRecord
    "stepbrobd.com"
    "com_stepbrobd"
  ;
}
