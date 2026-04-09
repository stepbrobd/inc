{ newHost, lib, ... }:

newHost (lib.fix (self: {
  name = "Roraima";
  hostName = "roraima";
  platform = "x86_64-linux";
  os = "nixos";
  provider = "netactuate";
  providerName = "NetActuate";
  type = "server";
  tags = [ "ysun" "router" "ranet" "prometheus" "loki" ];
  meta = { city = "Sao Paulo"; region = "BR-SP"; country = "BR"; continent = "South America"; postal = "01311-000"; };
  interface = "ens3";
  ipv4 = "148.163.220.57";
  ipv6 = "2607:f740:1::7f";
  ipam = {
    interface = "dummy0";
    ipv4 = "23.161.104.142";
    ipv6 = "2602:f590::23:161:104:142";
  };
  ranet.endpoints = let fqdn = "${self.hostName}.${lib.blueprint.provider.domain}"; in [
    { serial_number = "0"; address_family = "ip6"; address = fqdn; port = 13000; }
    { serial_number = "1"; address_family = "ip4"; address = fqdn; port = 13000; }
  ];
  ranet.gravity.prefix = "2a0c:b641:69c:e880::/60";
}))
