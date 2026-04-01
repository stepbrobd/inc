{ newHost, lib, ... }:

newHost (lib.fix (self: {
  name = "Lagern";
  hostName = "lagern";
  platform = "x86_64-linux";
  os = "nixos";
  provider = "aws";
  providerName = "AWS";
  type = "server";
  tags = [ "routee" "jitsi" "ranet" ];
  meta = { city = "Zurich"; region = "CH-ZH"; country = "CH"; continent = "Europe"; postal = "8001"; };
  interface = "ens5";
  ipv4 = "16.62.113.214";
  ipv6 = "2a05:d019:b00:b6f0:6981:b7c5:ff97:9eea";
  ipam = {
    interface = "dummy0";
    ipv4 = "23.161.104.135";
    ipv6 = "2602:f590::23:161:104:135";
  };
  ranet.endpoints = [
    { serial_number = "0"; address_family = "ip6"; address = self.ipv6; port = 13000; }
    { serial_number = "1"; address_family = "ip4"; address = self.ipv4; port = 13000; }
  ];
}))
