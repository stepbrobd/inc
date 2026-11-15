{ newHost, lib, ... }:

newHost (lib.fix (self: {
  name = "Faber";
  hostName = "faber";
  platform = "x86_64-linux";
  os = "nixos";
  provider = "vultr";
  providerName = "Vultr";
  type = "server";
  tags = [ "ysun" "router" "ranet3" "prometheus" "loki" "ci" ];
  meta = { city = "Singapore"; region = "SG"; country = "SG"; continent = "Asia"; postal = "139963"; };
  interface = "enp1s0";
  ipv4 = "45.76.156.95";
  ipv6 = "2001:19f0:4400:7881:5400:7ff:fe0d:ac7d";
  ipam = {
    interface = "dummy0";
    ipv4 = "23.161.104.146";
    ipv6 = "2602:f590::23:161:104:146";
  };
  ranet.endpoints = let fqdn = "${self.hostName}.${lib.blueprint.provider.domain}"; in [
    { serial_number = "0"; address_family = "ip6"; address = fqdn; port = 13000; }
    { serial_number = "1"; address_family = "ip4"; address = fqdn; port = 13000; }
  ];
  ranet.gravity.prefix = "2a0c:b641:69c:12e0::/60";
}))
