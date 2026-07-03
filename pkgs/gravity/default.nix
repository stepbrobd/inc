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
          extensions =
            let
              base = lib.removeSuffix "0::/60" (h.ranet.gravity.prefix or "");
              hasPrefix = h ? ranet && h.ranet ? gravity && lib.hasSuffix "0::/60" h.ranet.gravity.prefix;
            in
            # segment routing SIDs at the "6" nibble subspace
              # ::1 = End.DT46 (exit here)
              # ::2 = End (transit waypoint)
            lib.optional hasPrefix {
              type = "srv6";
              enabled = true;
              addresses = [ "${base}6::1" "${base}6::2" ];
            };
        };
      })
      (lib.collect
        (h: h ? ranet && h.ranet ? endpoints && (lib.length h.ranet.endpoints) > 0)
        bp.hosts);
  };
in
((formats.json { }).generate "gravity.json" registry).overrideAttrs {
  passthru = { inherit registry; full = ./secrets.yaml; };
}
