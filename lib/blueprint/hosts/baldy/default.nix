{ newHost, lib, ... }:

newHost (lib.fix (self: {
  name = "Baldy";
  hostName = "baldy";
  platform = "x86_64-linux";
  os = "nixos";
  provider = "netactuate";
  providerName = "NetActuate";
  type = "server";
  tags = [ "ysun" "router" "ranet" "prometheus" "loki" ];
  meta = { city = "Los Angeles"; region = "US-CA"; country = "US"; continent = "North America"; postal = "90009"; };
  interface = "ens3";
  ipv4 = "208.111.40.54";
  ipv6 = "2607:f740:c::a49";
  ipam = {
    interface = "dummy0";
    ipv4 = "23.161.104.139";
    ipv6 = "2602:f590::23:161:104:139";
  };
  ranet.endpoints = let fqdn = "${self.hostName}.${lib.blueprint.provider.domain}"; in [
    { serial_number = "0"; address_family = "ip6"; address = fqdn; port = 13000; }
    { serial_number = "1"; address_family = "ip4"; address = fqdn; port = 13000; }
  ];
  ranet.gravity.prefix = "2a0c:b641:69c:6c40::/60";
}))
