{ newHost, lib, ... }:

newHost (lib.fix (self: {
  name = "Morasko";
  hostName = "morasko";
  platform = "x86_64-linux";
  os = "nixos";
  provider = "pozman";
  providerName = "POZMAN";
  type = "server";
  tags = [ "routee" "ranet" "prometheus" "loki" ];
  meta = { city = "Poznan"; region = "PL-30"; country = "PL"; continent = "Europe"; postal = "61-101"; };
  interface = "ens4";
  ipv4 = "62.3.175.30";
  ipv6 = "2001:808:3:60d:f816:3eff:fe3a:8fd6";
  ipam = {
    interface = "dummy0";
    ipv4 = "23.161.104.134";
    ipv6 = "2602:f590::23:161:104:134";
  };
  ranet.endpoints = let fqdn = "${self.hostName}.${lib.blueprint.provider.domain}"; in [
    { serial_number = "0"; address_family = "ip6"; address = fqdn; port = 13000; }
    { serial_number = "1"; address_family = "ip4"; address = fqdn; port = 13000; }
  ];
  ranet.gravity.prefix = "2a0c:b641:69c:9390::/60";
}))
