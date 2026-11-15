{ newHost, lib, ... }:

newHost (lib.fix (self: {
  name = "Watchung";
  hostName = "watchung";
  platform = "x86_64-linux";
  os = "nixos";
  provider = "vultr";
  providerName = "Vultr";
  type = "server";
  tags = [ "ysun" "router" "ranet3" "prometheus" "loki" "ci" ];
  meta = { city = "Piscataway"; region = "US-NJ"; country = "US"; continent = "North America"; postal = "08854"; };
  interface = "enp1s0";
  ipv4 = "66.135.16.235";
  ipv6 = "2001:19f0:0:8159:5400:7ff:fe0d:aca2";
  ipam = {
    interface = "dummy0";
    ipv4 = "23.161.104.147";
    ipv6 = "2602:f590::23:161:104:147";
  };
  ranet.endpoints = let fqdn = "${self.hostName}.${lib.blueprint.provider.domain}"; in [
    { serial_number = "0"; address_family = "ip6"; address = fqdn; port = 13000; }
    { serial_number = "1"; address_family = "ip4"; address = fqdn; port = 13000; }
  ];
  ranet.gravity.prefix = "2a0c:b641:69c:ff10::/60";
}))
