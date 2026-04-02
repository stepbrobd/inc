{ newHost, lib, ... }:

newHost (lib.fix (self: {
  name = "Halti";
  hostName = "halti";
  platform = "x86_64-linux";
  os = "nixos";
  provider = "garnix";
  providerName = "Garnix";
  type = "server";
  tags = [ "routee" "grafana" "ranet" ];
  meta = { city = "Helsinki"; region = "FI-18"; country = "FI"; continent = "Europe"; postal = "00100"; };
  interface = "enp1s0";
  ipv4 = "37.27.181.83";
  ipv6 = "2a01:4f9:c012:7b3a::1";
  ipam = {
    interface = "dummy0";
    ipv4 = "23.161.104.134";
    ipv6 = "2602:f590::23:161:104:134";
  };
  ranet.endpoints = let fqdn = "${self.hostName}.${lib.blueprint.provider.domain}"; in [
    { serial_number = "0"; address_family = "ip6"; address = fqdn; port = 13000; }
    { serial_number = "1"; address_family = "ip4"; address = fqdn; port = 13000; }
  ];
  ranet.gravity.prefix = "2a0c:b641:69c:43c0::/60";
}))
