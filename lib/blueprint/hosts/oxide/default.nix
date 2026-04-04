{ newHost, lib, ... }:

newHost (lib.fix (self: {
  name = "Oxide";
  hostName = "oxide";
  platform = "x86_64-linux";
  os = "nixos";
  provider = "oxide";
  providerName = "Oxide Computer";
  type = "server";
  tags = [ ];
  meta = { city = "Fremont"; region = "US-CA"; country = "US"; continent = "North America"; postal = "94536"; };
  interface = "enp0s8";
  ipv4 = "134.195.24.131";
  # ipv6 = "";
  # ipam = {
  #   interface = "dummy0";
  #   ipv4 = "";
  #   ipv6 = "";
  # };
  # ranet.endpoints = let fqdn = "${self.hostName}.${lib.blueprint.provider.domain}"; in [
  #   { serial_number = "0"; address_family = "ip6"; address = fqdn; port = 13000; }
  #   { serial_number = "1"; address_family = "ip4"; address = fqdn; port = 13000; }
  # ];
  # ranet.gravity.prefix = "2a0c:b641:69c:4d70::/60";
}))
