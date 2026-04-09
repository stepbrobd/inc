{ newHost, lib, ... }:

newHost (lib.fix (self: {
  name = "Lantau";
  hostName = "lantau";
  platform = "x86_64-linux";
  os = "nixos";
  provider = "netactuate";
  providerName = "NetActuate";
  type = "server";
  tags = [ "ysun" "router" "ranet" "prometheus" "loki" ];
  meta = { city = "Hong Kong"; region = "HK"; country = "HK"; continent = "Asia"; postal = "999077"; };
  interface = "ens3";
  ipv4 = "103.6.84.26";
  ipv6 = "2403:2500:8000:1::71d";
  ipam = {
    interface = "dummy0";
    ipv4 = "23.161.104.141";
    ipv6 = "2602:f590::23:161:104:141";
  };
  ranet.endpoints = let fqdn = "${self.hostName}.${lib.blueprint.provider.domain}"; in [
    { serial_number = "0"; address_family = "ip6"; address = fqdn; port = 13000; }
    { serial_number = "1"; address_family = "ip4"; address = fqdn; port = 13000; }
  ];
  ranet.gravity.prefix = "2a0c:b641:69c:cfb0::/60";
}))
