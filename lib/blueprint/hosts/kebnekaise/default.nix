{ newHost, lib, ... }:

newHost (lib.fix (self: {
  name = "Kebnekaise";
  hostName = "kebnekaise";
  platform = "x86_64-linux";
  os = "nixos";
  provider = "vultr";
  providerName = "Vultr";
  type = "server";
  tags = [ "ysun" "router" "kanidm" "glance" "ranet3" "prometheus" "loki" "csp" "ci" ];
  meta = { city = "Stockholm"; region = "SE-AB"; country = "SE"; continent = "Europe"; postal = "111 20"; };
  interface = "enp1s0";
  ipv4 = "70.34.200.17";
  ipv6 = "2a05:f480:2000:1d20:5400:7ff:fe0d:ac00";
  ipam = {
    interface = "dummy0";
    ipv4 = "23.161.104.150";
    ipv6 = "2602:f590::23:161:104:150";
  };
  ranet.endpoints = let fqdn = "${self.hostName}.${lib.blueprint.provider.domain}"; in [
    { serial_number = "0"; address_family = "ip6"; address = fqdn; port = 13000; }
    { serial_number = "1"; address_family = "ip4"; address = fqdn; port = 13000; }
  ];
  ranet.gravity.prefix = "2a0c:b641:69c:a210::/60";
}))
