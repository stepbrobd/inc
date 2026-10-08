{ newHost, ... }:

newHost {
  name = "MacBook";
  hostName = "macbook";
  platform = "aarch64-darwin";
  os = "darwin";
  provider = "owned";
  providerName = "Apple";
  type = "laptop";
  tags = [ "ranet3" ];
  meta = { city = "Grenoble"; region = "FR-ARA"; country = "FR"; continent = "Europe"; postal = "38000"; };
  ipam = {
    ipv4 = "23.161.104.119";
    ipv6 = "2602:f590::23:161:104:119";
  };
  ranet.endpoints = [
    { serial_number = "0"; address_family = "ip6"; port = 13003; }
    { serial_number = "1"; address_family = "ip4"; port = 13003; }
  ];
  ranet.gravity.prefix = "2a0c:b641:69c:bde0::/60";
}
