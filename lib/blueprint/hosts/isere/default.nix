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
  ranet.endpoints = [
    { serial_number = "0"; address_family = "ip6"; address = self.ipv6; port = 13000; }
  ];
}))
