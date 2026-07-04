{ newHost, ... }:

newHost {
  name = "Framework";
  hostName = "framework";
  platform = "x86_64-linux";
  os = "nixos";
  provider = "owned";
  providerName = "Framework";
  type = "laptop";
  tags = [ "graphical" "niri" "noctalia" "nixbuild" "nix-community" "ranet" ];
  meta = { city = "Grenoble"; region = "FR-ARA"; country = "FR"; continent = "Europe"; postal = "38000"; };
  interface = "wlp170s0";
  ipam = {
    interface = "dummy0";
    ipv4 = "23.161.104.117";
    ipv6 = "2602:f590::23:161:104:117";
  };
  ranet.endpoints = [
    { serial_number = "0"; address_family = "ip6"; port = 13000; }
    { serial_number = "1"; address_family = "ip4"; port = 13000; }
  ];
  ranet.gravity.prefix = "2a0c:b641:69c:8c0::/60";
}
