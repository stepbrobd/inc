{ newHost, lib, ... }:

newHost (lib.fix (self: {
  name = "Walberla";
  hostName = "walberla";
  platform = "x86_64-linux";
  os = "nixos";
  provider = "hetzner";
  providerName = "Hetzner Cloud";
  type = "server";
  tags = [ "routee" "glance" "golink" "kanidm" "ranet" ];
  meta = { city = "Falkenstein"; region = "DE-SN"; country = "DE"; continent = "Europe"; postal = "08223"; };
  interface = "eth0";
  ipv4 = "23.88.126.45";
  ipv6 = "2a01:4f8:c17:4b75::1";
  ipam = {
    interface = "dummy0";
    ipv4 = "23.161.104.137";
    ipv6 = "2602:f590::23:161:104:137";
  };
  ranet.endpoints = [
    { serial_number = "0"; address_family = "ip6"; address = self.ipv6; port = 13000; }
  ];
}))
