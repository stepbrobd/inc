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
  ranet.endpoints = [
    { serial_number = "0"; address_family = "ip6"; address = self.ipv6; port = 13000; }
    { serial_number = "1"; address_family = "ip4"; address = self.ipv4; port = 13000; }
  ];
}))
