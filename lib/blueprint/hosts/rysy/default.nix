{ newHost, lib, ... }:

newHost (lib.fix (self: {
  name = "Rysy";
  hostName = "rysy";
  platform = "x86_64-linux";
  os = "nixos";
  provider = "netactuate";
  providerName = "NetActuate";
  type = "server";
  tags = [ ];
  meta = { city = "Warsaw"; region = "PL-14"; country = "PL"; continent = "Europe"; postal = "00-001"; };
  interface = "ens3";
  ipv4 = "45.159.98.222";
  ipv6 = "2a00:dd80:40:100::6f";
  # ipam = {
  #   interface = "dummy0";
  #   ipv4 = "";
  #   ipv6 = "";
  # };
  # ranet.endpoints = let fqdn = "${self.hostName}.${lib.blueprint.provider.domain}"; in [
  #   { serial_number = "0"; address_family = "ip6"; address = fqdn; port = 13000; }
  #   { serial_number = "1"; address_family = "ip4"; address = fqdn; port = 13000; }
  # ];
  # ranet.gravity.prefix = "";
}))
