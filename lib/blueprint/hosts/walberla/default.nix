{ newHost, lib, ... }:

newHost (lib.fix (self: {
  name = "Walberla";
  hostName = "walberla";
  platform = "x86_64-linux";
  os = "nixos";
  provider = "hetzner";
  providerName = "Hetzner Cloud";
  type = "server";
  tags = [ "routee" "glance" "golink" "kanidm" "ranet" "prometheus" "loki" ];
  meta = { city = "Falkenstein"; region = "DE-SN"; country = "DE"; continent = "Europe"; postal = "08223"; };
  interface = "eth0";
  ipv4 = "23.88.126.45";
  ipv6 = "2a01:4f8:c17:4b75::1";
  ipam = {
    interface = "dummy0";
    ipv4 = "23.161.104.137";
    ipv6 = "2602:f590::23:161:104:137";
  };
  ranet.endpoints = let fqdn = "${self.hostName}.${lib.blueprint.provider.domain}"; in [
    { serial_number = "0"; address_family = "ip6"; address = fqdn; port = 13000; }
    { serial_number = "1"; address_family = "ip4"; address = fqdn; port = 13000; }
  ];
  ranet.gravity.prefix = "2a0c:b641:69c:ae50::/60";
}))
