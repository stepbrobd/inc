{ lib, ... }:

let
  inherit (lib.terranix) forZone mkPersonalSiteRebind mkPurelyMailRecord;
in
{
  resource.cloudflare_dns_record = forZone "churn.cards"
    {
      cards_churn_apex = mkPersonalSiteRebind { name = "@"; };
    } // mkPurelyMailRecord
    "churn.cards"
    "cards_churn"
  ;
}
