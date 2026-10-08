{ newHost, ... }:

newHost {
  name = "XPS";
  hostName = "xps";
  platform = "x86_64-linux";
  os = "nixos";
  provider = "owned";
  providerName = "Dell";
  type = "laptop";
  tags = [ "graphical" "mango" "niri" "noctalia" "ranet3" ];
  meta = { city = "Grenoble"; region = "FR-ARA"; country = "FR"; continent = "Europe"; postal = "38000"; };
  ipam = {
    ipv4 = "23.161.104.118";
    ipv6 = "2602:f590::23:161:104:118";
  };
  ranet.endpoints = [
    { serial_number = "0"; address_family = "ip6"; port = 13002; }
    { serial_number = "1"; address_family = "ip4"; port = 13002; }
  ];
  ranet.gravity.prefix = "2a0c:b641:69c:bb30::/60";
}
