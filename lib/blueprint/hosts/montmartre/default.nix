{ newHost, lib, ... }:

newHost (lib.fix (self: {
  name = "Montmartre";
  hostName = "montmartre";
  platform = "x86_64-linux";
  os = "nixos";
  provider = "vultr";
  providerName = "Vultr";
  type = "server";
  tags = [ "ysun" "router" "ranet3" "prometheus" "loki" "csp" "ci" ];
  meta = { city = "Paris"; region = "FR-IDF"; country = "FR"; continent = "Europe"; postal = "75000"; };
  interface = "enp1s0";
  ipv4 = "217.69.1.195";
  ipv6 = "2001:19f0:6801:f5c:5400:7ff:fe0d:abbb";
  ipam = {
    interface = "dummy0";
    ipv4 = "23.161.104.145";
    ipv6 = "2602:f590::23:161:104:145";
  };
  ranet.endpoints = let fqdn = "${self.hostName}.${lib.blueprint.provider.domain}"; in [
    { serial_number = "0"; address_family = "ip6"; address = fqdn; port = 13000; }
    { serial_number = "1"; address_family = "ip4"; address = fqdn; port = 13000; }
  ];
  ranet.gravity.prefix = "2a0c:b641:69c:eb80::/60";
}))
