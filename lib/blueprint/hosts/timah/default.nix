{ newHost, lib, ... }:

newHost (lib.fix (self: {
  name = "Timah";
  hostName = "timah";
  platform = "x86_64-linux";
  os = "nixos";
  provider = "misaka";
  providerName = "Misaka Network";
  type = "server";
  tags = [ "ysun" "router" "ranet" ];
  meta = { city = "Singapore"; region = "SG"; country = "SG"; continent = "Asia"; postal = "139963"; };
  interface = "enp3s0";
  ipv4 = "194.114.138.187";
  ipv6 = "2407:b9c0:e002:25c:26a3:f0ff:fe45:a7b7";
  ipam = {
    interface = "dummy0";
    ipv4 = "23.161.104.131";
    ipv6 = "2602:f590::23:161:104:131";
  };
  ranet.endpoints = [
    { serial_number = "0"; address_family = "ip6"; address = self.ipv6; port = 13000; }
  ];
}))
