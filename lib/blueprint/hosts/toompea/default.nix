{ newHost, lib, ... }:

newHost (lib.fix (self: {
  name = "Toompea";
  hostName = "toompea";
  platform = "x86_64-linux";
  os = "nixos";
  provider = "xtom";
  providerName = "xTom";
  type = "server";
  tags = [ "anycast" "router" "calibre" "plausible" "ranet" ];
  meta = { city = "Tallinn"; region = "EE-37"; country = "EE"; continent = "Europe"; postal = "10111"; };
  interface = "enp6s18";
  ipv4 = "185.194.53.29";
  ipv6 = "2a04:6f00:4::a5";
  ipam = {
    interface = "dummy0";
    ipv4 = "23.161.104.128";
    ipv6 = "2602:f590::23:161:104:128";
  };
  ranet.endpoints = [
    { serial_number = "0"; address_family = "ip6"; address = self.ipv6; port = 13000; }
  ];
}))
