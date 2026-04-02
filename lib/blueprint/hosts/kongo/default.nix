{ newHost, lib, ... }:

newHost (lib.fix (self: {
  name = "Kongo";
  hostName = "kongo";
  platform = "x86_64-linux";
  os = "nixos";
  provider = "vultr";
  providerName = "Vultr";
  type = "server";
  tags = [ "ysun" "router" "ranet" ];
  meta = { city = "Osaka"; region = "JP-27"; country = "JP"; continent = "Asia"; postal = "540-0001"; };
  interface = "enp1s0";
  ipv4 = "45.32.59.137";
  ipv6 = "2001:19f0:7002:327:5400:5ff:febb:599b";
  ipam = {
    interface = "dummy0";
    ipv4 = "23.161.104.130";
    ipv6 = "2602:f590::23:161:104:130";
  };
  ranet.endpoints = let fqdn = "${self.hostName}.${lib.blueprint.provider.domain}"; in [
    { serial_number = "0"; address_family = "ip6"; address = fqdn; port = 13000; }
    { serial_number = "1"; address_family = "ip4"; address = fqdn; port = 13000; }
  ];
  ranet.gravity.prefix = "2a0c:b641:69c:6a50::/60";
}))
