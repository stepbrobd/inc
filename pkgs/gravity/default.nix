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
          # extensions = [
          #   # stateless NAT64 (v4-over-v6 via jool/tayga)
          #   # enable per node to provide IPv4 connectivity through the v6 only mesh
          #   # prefix: list of v4 CIDRs this node can translate
          #   { type = "divi"; enabled = false; prefix = [ ]; }
          #   # regment routing (explicit path selection via IPv6 header)
          #   # addresses: list of SRv6 SID endpoints on this node
          #   { type = "srv6"; enabled = false; addresses = [ ]; }
          # ];
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
