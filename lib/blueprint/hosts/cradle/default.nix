{ newHost, lib, ... }:

newHost (lib.fix (self: {
  name = "Cradle";
  hostName = "cradle";
  platform = "x86_64-linux";
  os = "nixos";
  provider = "netactuate";
  providerName = "NetActuate";
  type = "server";
  tags = [ ];
  meta = { city = "Sydney"; region = "AU-NSW"; country = "AU"; continent = "Oceania"; postal = "2000"; };
  interface = "ens3";
  ipv4 = "43.245.48.187";
  ipv6 = "2403:2500:9000:1::dc6";
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
