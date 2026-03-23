{ lib }:

# bruh i'm not using `evalModules` here
let
  newUser =
    { userName # e.g. "ysun"
    , fullName # e.g. "Yifei Sun"
    , keys     # e.g. [ "ssh-ed25519 ..." ]
    }: {
      name = userName;
      description = fullName;
      openssh.authorizedKeys.keys = keys;
    };

  newHost =
    { hostName # e.g. "bachtel"
    , platform # e.g. "x86_64-linux"
    , os # e.g. "darwin" or "nixos"
    , provider # e.g. "aws", "garnix", "hetzner", "owned", "ssdnodes", "vultr", "xtom"
    , type # e.g. "laptop", "desktop", "server", "rpi"
    , domain ? "sd.ysun.co"
    , tags ? [ ]
    , interface ? null # e.g. "eth0", "enp1s0" primary outbound network interface
    , ipv4 ? null
    , ipv6 ? null
    , name ? null # e.g. "Butte" display name
    , meta ? { } # e.g. { country, region, city, postal, continent }
    , ipam ? { }
    , ranet ? { }
    , services ? { }
    }: {
      inherit platform os provider type; # metadata
      inherit hostName name domain interface ipv4 ipv6 ipam ranet meta; # networking
      inherit services;
      fqdn = "${hostName}.${domain}";
      tags = [ "server" ] ++ tags;
    };
in
{
  ranet = {
    organization = "ysun";
    publicKey = ''
      -----BEGIN PUBLIC KEY-----
      MCowBQYDK2VwAyEADThQqitYOEGZgDk+S2Y9ZcLJVozx3hEOdyjpdK7NOY0=
      -----END PUBLIC KEY-----
    '';
    port = 13000;
  };

  tailscale = {
    tailnet = "tail650e82.ts.net";
    domain = "ts.ysun.co";
    zone = "ysun.co";
    prefix = "co_ysun_ts";
  };

  users.ysun = newUser {
    userName = "ysun";
    fullName = "Yifei Sun";
    keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBVZ9mzYNxccuh3uQR7Hly4KjhbRh4s6UlGQe2GjMtIC" # framework
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHaMDj2MpMGwDcUfDcfNHb9UR7gA5Pgtt4EPyC+1OkBP" # xps
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJ47Qtg6qSenUh6Whg3ZIpIhdZZdqdG+L1z2f9UnB+Mw" # macbook
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOQCjwNmB60FQhDncIyX/wCRAPIlLD5KLAGrgAdt4xGw" # servercat
    ];
  };

  # laptops
  hosts.framework = { };
  hosts.macbook = { };

  # servers
  hosts.butte = newHost (lib.fix (self: {
    name = "Butte";
    hostName = "butte";
    platform = "x86_64-linux";
    os = "nixos";
    provider = "virtua";
    type = "server";
    tags = [ "anycast" "router" "ranet" ];
    meta = { city = "Paris"; region = "FR-IDF"; country = "FR"; continent = "Europe"; postal = "75000"; };
    interface = "eth0";
    ipv4 = "185.234.100.120";
    ipv6 = "2a07:8dc0:1c:0:48:f1ff:febe:1c6";
    ipam = {
      interface = "dummy0";
      ipv4 = "23.161.104.132";
      ipv6 = "2602:f590::23:161:104:132";
    };
    ranet.endpoints = [
      { serial_number = "0"; address_family = "ip6"; address = self.ipv6; port = 13000; }
    ];
  }));

  hosts.halti = newHost (lib.fix (self: {
    name = "Halti";
    hostName = "halti";
    platform = "x86_64-linux";
    os = "nixos";
    provider = "garnix";
    type = "server";
    tags = [ "routee" "grafana" "ranet" ];
    meta = { city = "Helsinki"; region = "FI-18"; country = "FI"; continent = "Europe"; postal = "00100"; };
    interface = "enp1s0";
    ipv4 = "37.27.181.83";
    ipv6 = "2a01:4f9:c012:7b3a::1";
    ipam = {
      interface = "dummy0";
      ipv4 = "23.161.104.134";
      ipv6 = "2602:f590::23:161:104:134";
    };
    ranet.endpoints = [
      { serial_number = "0"; address_family = "ip6"; address = self.ipv6; port = 13000; }
    ];
  }));

  hosts.isere = newHost (lib.fix (self: {
    name = "Isere";
    hostName = "isere";
    platform = "aarch64-linux";
    os = "nixos";
    provider = "owned";
    type = "rpi";
    tags = [ "routee" "home-assistant" "vaultwarden" "ntpd-rs" "ranet" ];
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
  }));

  hosts.highline = newHost (lib.fix (self: {
    name = "Highline";
    hostName = "highline";
    platform = "x86_64-linux";
    os = "nixos";
    provider = "neptune";
    type = "server";
    tags = [ "anycast" "router" "ranet" ];
    meta = { city = "New York City"; region = "US-NY"; country = "US"; continent = "North America"; postal = "10001"; };
    interface = "ens3";
    ipv4 = "172.82.22.183";
    ipv6 = "2602:fe2e:4:b2:fd:87ff:fe11:53cb";
    ipam = {
      interface = "dummy0";
      ipv4 = "23.161.104.129";
      ipv6 = "2602:f590::23:161:104:129";
    };
    ranet.endpoints = [
      { serial_number = "0"; address_family = "ip6"; address = self.ipv6; port = 13000; }
    ];
  }));

  hosts.kongo = newHost (lib.fix (self: {
    name = "Kongo";
    hostName = "kongo";
    platform = "x86_64-linux";
    os = "nixos";
    provider = "vultr";
    type = "server";
    tags = [ "anycast" "router" "ranet" ];
    meta = { city = "Osaka"; region = "JP-27"; country = "JP"; continent = "Asia"; postal = "540-0001"; };
    interface = "enp1s0";
    ipv4 = "45.32.59.137";
    ipv6 = "2001:19f0:7002:0327:5400:05ff:febb:599b";
    ipam = {
      interface = "dummy0";
      ipv4 = "23.161.104.130";
      ipv6 = "2602:f590::23:161:104:130";
    };
    ranet.endpoints = [
      { serial_number = "0"; address_family = "ip6"; address = self.ipv6; port = 13000; }
    ];
  }));

  hosts.lagern = newHost (lib.fix (self: {
    name = "Lagern";
    hostName = "lagern";
    platform = "x86_64-linux";
    os = "nixos";
    provider = "aws";
    type = "server";
    tags = [ "routee" "jitsi" "ranet" ];
    meta = { city = "Zurich"; region = "CH-ZH"; country = "CH"; continent = "Europe"; postal = "8001"; };
    interface = "ens5";
    ipv4 = "16.62.113.214";
    ipv6 = "2a05:d019:b00:b6f0:6981:b7c5:ff97:9eea";
    ipam = {
      interface = "dummy0";
      ipv4 = "23.161.104.135";
      ipv6 = "2602:f590::23:161:104:135";
    };
    ranet.endpoints = [
      { serial_number = "0"; address_family = "ip6"; address = self.ipv6; port = 13000; }
    ];
  }));

  hosts.odake = newHost (lib.fix (self: {
    name = "Odake";
    hostName = "odake";
    platform = "x86_64-linux";
    os = "nixos";
    provider = "ssdnodes";
    type = "server";
    tags = [ "routee" "attic" "hydra" "neogrok" "ranet" ];
    meta = { city = "Tokyo"; region = "JP-13"; country = "JP"; continent = "Asia"; postal = "100-0001"; };
    interface = "enp3s0";
    ipv4 = "209.182.234.194";
    ipv6 = "2602:ff16:14:0:1:56:0:1";
    ipam = {
      interface = "dummy0";
      ipv4 = "23.161.104.136";
      ipv6 = "2602:f590::23:161:104:136";
    };
    ranet.endpoints = [
      { serial_number = "0"; address_family = "ip6"; address = self.ipv6; port = 13000; }
    ];
  }));

  hosts.timah = newHost (lib.fix (self: {
    name = "Timah";
    hostName = "timah";
    platform = "x86_64-linux";
    os = "nixos";
    provider = "misaka";
    type = "server";
    tags = [ "anycast" "router" "ranet" ];
    meta = { city = "Singapore"; region = "SG"; country = "SG"; continent = "Asia"; postal = "139963"; };
    interface = "enp3s0";
    ipv4 = "194.114.138.187";
    ipv6 = "2407:b9c0:e002:25c:26a3:f0ff:fe45:a7b7";
    ipam = {
      interface = "dummy0";
      ipv4 = "23.161.104.131";
      ipv6 = "2602:f590::23:161:104:131";
    };
    ranet.endpoints = [
      { serial_number = "0"; address_family = "ip6"; address = self.ipv6; port = 13000; }
    ];
  }));

  hosts.toompea = newHost (lib.fix (self: {
    name = "Toompea";
    hostName = "toompea";
    platform = "x86_64-linux";
    os = "nixos";
    provider = "xtom";
    type = "server";
    tags = [ "anycast" "router" "calibre" "plausible" "ranet" ];
    meta = { city = "Tallinn"; region = "EE-37"; country = "EE"; continent = "Europe"; postal = "10111"; };
    interface = "enp6s18";
    ipv4 = "185.194.53.29";
    ipv6 = "2a04:6f00:4::a5";
    ipam = {
      interface = "dummy0";
      ipv4 = "23.161.104.128";
      ipv6 = "2602:f590::23:161:104:128";
    };
    ranet.endpoints = [
      { serial_number = "0"; address_family = "ip6"; address = self.ipv6; port = 13000; }
    ];
  }));

  hosts.walberla = newHost (lib.fix (self: {
    name = "Walberla";
    hostName = "walberla";
    platform = "x86_64-linux";
    os = "nixos";
    provider = "hetzner";
    type = "server";
    tags = [ "routee" "glance" "golink" "kanidm" "ranet" ];
    meta = { city = "Falkenstein"; region = "DE-SN"; country = "DE"; continent = "Europe"; postal = "08223"; };
    interface = "eth0";
    ipv4 = "23.88.126.45";
    ipv6 = "2a01:4f8:c17:4b75::1";
    ipam = {
      interface = "dummy0";
      ipv4 = "23.161.104.137";
      ipv6 = "2602:f590::23:161:104:137";
    };
    ranet.endpoints = [
      { serial_number = "0"; address_family = "ip6"; address = self.ipv6; port = 13000; }
    ];
  }));

  prefixes = {
    experimental = {
      ipv4 = [ ];
      ipv6 = lib.map
        (prefix: {
          inherit prefix;
          option = lib.trim ''
            reject {
                bgp_path.prepend(18932);
              }
          '';
        })
        [
          "2602:f590:a::/48"
          "2602:f590:b::/48"
          "2602:f590:c::/48"
          "2602:f590:d::/48"
          "2602:f590:e::/48"
          "2602:f590:f::/48"
        ];
    };
  };
}
