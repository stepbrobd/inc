{ newHost, lib, ... }:

newHost (lib.fix (self: {
  name = "Feldberg";
  hostName = "feldberg";
  platform = "x86_64-linux";
  os = "nixos";
  provider = "vultr";
  providerName = "Vultr";
  type = "server";
  tags = [ "router" "jitsi" "ranet3" "prometheus" "loki" "csp" "ci" ];
  meta = { city = "Frankfurt"; region = "DE-HE"; country = "DE"; continent = "Europe"; postal = "60311"; };
  interface = "enp1s0";
  ipv4 = "80.240.18.75";
  ipv6 = "2a05:f480:1800:343a:5400:7ff:fe0d:aba7";
  ipam = {
    interface = "dummy0";
    ipv4 = "23.161.104.144";
    ipv6 = "2602:f590::23:161:104:144";
  };
  ranet.endpoints = let fqdn = "${self.hostName}.${lib.blueprint.provider.domain}"; in [
    { serial_number = "0"; address_family = "ip6"; address = fqdn; port = 13000; }
    { serial_number = "1"; address_family = "ip4"; address = fqdn; port = 13000; }
  ];
  ranet.gravity.prefix = "2a0c:b641:69c:39e0::/60";
}))
