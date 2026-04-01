{ newHost, lib, ... }:

newHost (lib.fix (self: {
  name = "Highline";
  hostName = "highline";
  platform = "x86_64-linux";
  os = "nixos";
  provider = "neptune";
  providerName = "Neptune Networks";
  type = "server";
  tags = [ "ysun" "router" "ranet" ];
  meta = { city = "New York City"; region = "US-NY"; country = "US"; continent = "North America"; postal = "10001"; };
  interface = "ens3";
  ipv4 = "172.82.22.183";
  ipv6 = "2602:fe2e:4:b2:fd:87ff:fe11:53cb";
  ipam = {
    interface = "dummy0";
    ipv4 = "23.161.104.129";
    ipv6 = "2602:f590::23:161:104:129";
  };
  ranet.endpoints = [
    { serial_number = "0"; address_family = "ip6"; address = self.ipv6; port = 13000; }
    { serial_number = "1"; address_family = "ip4"; address = self.ipv4; port = 13000; }
  ];
}))
