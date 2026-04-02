{ newHost, lib, ... }:

newHost (lib.fix (self: {
  name = "Toompea";
  hostName = "toompea";
  platform = "x86_64-linux";
  os = "nixos";
  provider = "xtom";
  providerName = "xTom";
  type = "server";
  tags = [ "ysun" "router" "calibre-web" "plausible" "ranet" "prometheus" "loki" ];
  meta = { city = "Tallinn"; region = "EE-37"; country = "EE"; continent = "Europe"; postal = "10111"; };
  interface = "enp6s18";
  ipv4 = "185.194.53.29";
  ipv6 = "2a04:6f00:4::a5";
  ipam = {
    interface = "dummy0";
    ipv4 = "23.161.104.128";
    ipv6 = "2602:f590::23:161:104:128";
  };
  ranet.endpoints = let fqdn = "${self.hostName}.${lib.blueprint.provider.domain}"; in [
    { serial_number = "0"; address_family = "ip6"; address = fqdn; port = 13000; }
    { serial_number = "1"; address_family = "ip4"; address = fqdn; port = 13000; }
  ];
  ranet.gravity.prefix = "2a0c:b641:69c:98d0::/60";
}))
