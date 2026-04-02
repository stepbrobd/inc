{ lib, formats }:

let
  bp = lib.blueprint;

  registry = {
    public_key = lib.trim bp.ranet.publicKey;
    organization = bp.ranet.organization;

    nodes = lib.map
      (h: {
        common_name = h.hostName;
        endpoints = h.ranet.endpoints;
        remarks = {
          prefix = h.ranet.gravity.prefix or null;
          region = with h.meta; "${city}, ${country}";
          provider = h.providerName;
          extensions = [
            { type = "divi"; enabled = false; prefix = [ ]; }
            { type = "srv6"; enabled = false; addresses = [ ]; }
          ];
        };
      })
      (lib.collect
        (h: h ? ranet && h.ranet ? endpoints && (lib.length h.ranet.endpoints) > 0)
        bp.hosts);
  };
in
((formats.json { }).generate "gravity.json" registry).overrideAttrs {
  passthru = { inherit registry; };
}
