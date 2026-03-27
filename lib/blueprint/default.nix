{ lib }:

# bruh i'm not using `evalModules` here
let
  newUser =
    { userName # e.g. "ysun"
    , fullName # e.g. "Yifei Sun"
    , profilePicture ? null
    , wallpapersDir ? null
    , keys ? [ ] # e.g. [ "ssh-ed25519 ..." ]
    }: {
      name = userName;
      description = fullName;
      openssh.authorizedKeys.keys = keys;

      meta = { inherit profilePicture wallpapersDir; };
    };

  newHost =
    { hostName # e.g. "bachtel"
    , platform # e.g. "x86_64-linux"
    , os # e.g. "darwin" or "nixos"
    , provider # e.g. "aws", "hetzner", "vultr" lowercase tag for colmena deployment filtering
    , providerName ? provider # e.g. "AWS", "Hetzner", "Vultr" display name for DNS comments
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
      inherit platform os provider providerName type; # metadata
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

  users = lib.loadAll {
    dir = ./users;
    args = { inherit newUser lib; };
  };

  hosts = lib.loadAll {
    dir = ./hosts;
    args = { inherit newHost lib; };
  };

  services = {
    attic.domain = "cache.ysun.co";
    calibre-web.domain = "read.ysun.co";
    glance.domain = "home.ysun.co";
    grafana.domain = "otel.ysun.co";
    home-assistant.domain = "ha.ysun.co";
    hydra.domain = "hydra.ysun.co";
    jitsi.domain = "meet.ysun.co";
    kanidm.domain = "sso.ysun.co";
    neogrok.domain = "grep.ysun.co";
    ntpd-rs.domain = "time.ysun.co";
    plausible.domain = "stats.ysun.co";
    vaultwarden.domain = "vault.ysun.co";
  };

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
