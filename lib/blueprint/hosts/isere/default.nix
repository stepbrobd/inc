{ newHost, lib, ... }:

newHost (lib.fix (self: {
  name = "Isere";
  hostName = "isere";
  platform = "aarch64-linux";
  os = "nixos";
  provider = "owned";
  providerName = "Raspberry Pi 5B";
  type = "server";
  tags = [ "rpi" "routee" "home-assistant" "vaultwarden" "ntpd-rs" "ranet" ];
  meta = { city = "Grenoble"; region = "FR-ARA"; country = "FR"; continent = "Europe"; postal = "38000"; };
  interface = "end0";
  ipv4 = "88.140.186.193";
  ipv6 = "2001:470:1f12:441::2";
  ipam = {
    interface = "dummy0";
    ipv4 = "23.161.104.133";
    ipv6 = "2602:f590::23:161:104:133";
  };
  ranet.endpoints = let fqdn = "${self.hostName}.${lib.blueprint.provider.domain}"; in [
    { serial_number = "0"; address_family = "ip6"; address = fqdn; port = 13000; }
    { serial_number = "1"; address_family = "ip4"; address = fqdn; port = 13000; }
  ];
  ranet.gravity.prefix = "2a0c:b641:69c:49c0::/60";
}))
