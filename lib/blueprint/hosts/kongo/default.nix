{ newHost, lib, ... }:

newHost (lib.fix (self: {
  name = "Kongo";
  hostName = "kongo";
  platform = "x86_64-linux";
  os = "nixos";
  provider = "vultr";
  providerName = "Vultr";
  type = "server";
  tags = [ "ysun" "router" "ranet3" "prometheus" "loki" "ci" ];
  meta = { city = "Tokyo"; region = "JP-13"; country = "JP"; continent = "Asia"; postal = "100-0001"; };
  interface = "enp1s0";
  ipv4 = "167.179.116.147";
  ipv6 = "2401:c080:1000:514e:5400:7ff:fe0c:b3ad";
  ipam = {
    interface = "dummy0";
    ipv4 = "23.161.104.130";
    ipv6 = "2602:f590::23:161:104:130";
  };
  ranet.endpoints = let fqdn = "${self.hostName}.${lib.blueprint.provider.domain}"; in [
    { serial_number = "0"; address_family = "ip6"; address = fqdn; port = 13000; }
    { serial_number = "1"; address_family = "ip4"; address = fqdn; port = 13000; }
  ];
  ranet.gravity.prefix = "2a0c:b641:69c:6a50::/60";
}))
