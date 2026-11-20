{ newHost, lib, ... }:

newHost (lib.fix (self: {
  name = "Namsan";
  hostName = "namsan";
  platform = "x86_64-linux";
  os = "nixos";
  provider = "vultr";
  providerName = "Vultr";
  type = "server";
  tags = [ "ysun" "router" "ranet3" "prometheus" "loki" "csp" "ci" ];
  meta = { city = "Seoul"; region = "KR-11"; country = "KR"; continent = "Asia"; postal = "04524"; };
  interface = "enp1s0";
  ipv4 = "158.247.222.209";
  ipv6 = "2401:c080:1c02:903:5400:7ff:fe0d:ac22";
  ipam = {
    interface = "dummy0";
    ipv4 = "23.161.104.149";
    ipv6 = "2602:f590::23:161:104:149";
  };
  ranet.endpoints = let fqdn = "${self.hostName}.${lib.blueprint.provider.domain}"; in [
    { serial_number = "0"; address_family = "ip6"; address = fqdn; port = 13000; }
    { serial_number = "1"; address_family = "ip4"; address = fqdn; port = 13000; }
  ];
  ranet.gravity.prefix = "2a0c:b641:69c:1940::/60";
}))
