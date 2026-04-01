{ newHost, lib, ... }:

newHost (lib.fix (self: {
  name = "Odake";
  hostName = "odake";
  platform = "x86_64-linux";
  os = "nixos";
  provider = "ssdnodes";
  providerName = "SSDNodes";
  type = "server";
  tags = [ "routee" "attic" "hydra" "neogrok" "ranet" ];
  meta = { city = "Tokyo"; region = "JP-13"; country = "JP"; continent = "Asia"; postal = "100-0001"; };
  interface = "enp3s0";
  ipv4 = "209.182.234.194";
  ipv6 = "2602:ff16:14:0:1:56:0:1";
  ipam = {
    interface = "dummy0";
    ipv4 = "23.161.104.136";
    ipv6 = "2602:f590::23:161:104:136";
  };
  ranet.endpoints = [
    { serial_number = "0"; address_family = "ip6"; address = self.ipv6; port = 13000; }
    { serial_number = "1"; address_family = "ip4"; address = self.ipv4; port = 13000; }
  ];
}))
