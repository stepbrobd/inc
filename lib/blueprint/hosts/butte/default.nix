{ newHost, lib, ... }:

newHost (lib.fix (self: {
  name = "Butte";
  hostName = "butte";
  platform = "x86_64-linux";
  os = "nixos";
  provider = "virtua";
  providerName = "Virtua";
  type = "server";
  tags = [ "ysun" "router" "ranet" ];
  meta = { city = "Paris"; region = "FR-IDF"; country = "FR"; continent = "Europe"; postal = "75000"; };
  interface = "eth0";
  ipv4 = "185.234.100.120";
  ipv6 = "2a07:8dc0:1c:0:48:f1ff:febe:1c6";
  ipam = {
    interface = "dummy0";
    ipv4 = "23.161.104.132";
    ipv6 = "2602:f590::23:161:104:132";
  };
  ranet.endpoints = let fqdn = "${self.hostName}.${lib.blueprint.provider.domain}"; in [
    { serial_number = "0"; address_family = "ip6"; address = fqdn; port = 13000; }
    { serial_number = "1"; address_family = "ip4"; address = fqdn; port = 13000; }
  ];
  ranet.gravity.prefix = "2a0c:b641:69c:2900::/60";
}))
