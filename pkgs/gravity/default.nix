{ lib, formats }:

let
  registry = {
    public_key = lib.blueprint.ranet.publicKey;
    organization = lib.blueprint.ranet.organization;

    nodes = lib.map
      (h: {
        common_name = h.hostName;
        endpoints = h.ranet.endpoints;
        remarks = {
          region = with h.meta; "${city}, ${country}";
          provider = h.providerName;
          prefix = null; # TODO: what is this?
          extensions = [
            {
              # wtf is this
              type = "divi";
              enabled = false;
              prefix = [ ];
            }
            {
              # wtf is this
              type = "srv6";
              enabled = false;
              prefix = [ ];
            }
          ];
        };
      })
      (lib.collect
        (h: lib.hasAttrByPath [ "ranet" "endpoints" ] h && (lib.length h.ranet.endpoints) > 0)
        lib.blueprint.hosts);
  };
in
((formats.json { }).generate "gravity.json" registry).overrideAttrs {
  passthru = { inherit registry; };
}
