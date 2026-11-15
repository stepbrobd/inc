{ newHost, lib, ... }:

newHost (lib.fix (self: {
  name = "Guadalupe";
  hostName = "guadalupe";
  platform = "x86_64-linux";
  os = "nixos";
  provider = "vultr";
  providerName = "Vultr";
  type = "server";
  tags = [ "ysun" "router" "ranet3" "prometheus" "loki" "ci" ];
  meta = { city = "Dallas"; region = "US-TX"; country = "US"; continent = "North America"; postal = "75201"; };
  interface = "enp1s0";
  ipv4 = "45.32.206.238";
  ipv6 = "2001:19f0:6400:24d9:5400:7ff:fe0d:acb9";
  ipam = {
    interface = "dummy0";
    ipv4 = "23.161.104.148";
    ipv6 = "2602:f590::23:161:104:148";
  };
  ranet.endpoints = let fqdn = "${self.hostName}.${lib.blueprint.provider.domain}"; in [
    { serial_number = "0"; address_family = "ip6"; address = fqdn; port = 13000; }
    { serial_number = "1"; address_family = "ip4"; address = fqdn; port = 13000; }
  ];
  ranet.gravity.prefix = "2a0c:b641:69c:52c0::/60";
}))
