{ newHost, lib, ... }:

newHost (lib.fix (self: {
  name = "Lagern";
  hostName = "lagern";
  platform = "x86_64-linux";
  os = "nixos";
  provider = "aws";
  providerName = "AWS";
  type = "server";
  tags = [ "routee" "jitsi" "ranet" "prometheus" "loki" ];
  meta = { city = "Zurich"; region = "CH-ZH"; country = "CH"; continent = "Europe"; postal = "8001"; };
  interface = "ens5";
  ipv4 = "16.62.113.214";
  ipv6 = "2a05:d019:b00:b6f0:6981:b7c5:ff97:9eea";
  ipam = {
    interface = "dummy0";
    ipv4 = "23.161.104.135";
    ipv6 = "2602:f590::23:161:104:135";
  };
  ranet.endpoints = let fqdn = "${self.hostName}.${lib.blueprint.provider.domain}"; in [
    { serial_number = "0"; address_family = "ip6"; address = fqdn; port = 13000; }
    { serial_number = "1"; address_family = "ip4"; address = fqdn; port = 13000; }
  ];
  ranet.gravity.prefix = "2a0c:b641:69c:7ce0::/60";
}))
