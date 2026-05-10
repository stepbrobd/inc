{ lib, ... }:

let
  inherit (lib) pipe;
  inherit (lib.blueprint) tailscale;
  inherit (lib.terranix) forZone tfRef;

  subdomain = lib.removeSuffix ".${tailscale.zone}" tailscale.domain;
  get_node_name = name: ''trimsuffix(${name}, ".${tailscale.tailnet}")'';
  for_each = tfRef ''
    { for d in data.tailscale_devices.all.devices :
        ${get_node_name "d.name"} => d
        if endswith(d.name, ".${tailscale.tailnet}") }
  '';
  name = pipe "each.value.name" [ get_node_name tfRef ];
  proxied = false;
  ipv4 = tfRef "each.value.addresses[0]";
  ipv6 = tfRef "each.value.addresses[1]";
in
{
  data.tailscale_devices.all = { };

  resource.tailscale_dns_preferences.preferences.magic_dns = true;

  resource.tailscale_dns_nameservers.nameservers.nameservers = [
    # NextDNS
    "2a07:a8c0::d8:664a"
    "2a07:a8c1::d8:664a"
    # still NextDNS but
    # only work with linked IP
    # "45.90.28.217"
    # "45.90.30.217"
  ];

  resource.tailscale_dns_search_paths.search_paths.search_paths = [
    # default, and added by default
    # ''''${data.sops_file.secrets.data["tailscale.tailnet_name"]}''
    tailscale.domain # rebind to cloudflare
  ];

  # cloudflare interop
  resource.cloudflare_dns_record = forZone tailscale.zone {
    "${tailscale.prefix}_v4" = {
      inherit for_each proxied;
      name = name + ".${subdomain}";
      type = "A";
      content = ipv4;
      comment = "Tailscale IPv4 - `tailscale whois ${ipv4}`";
    };
    "${tailscale.prefix}_v6" = {
      inherit for_each proxied;
      name = name + ".${subdomain}";
      type = "AAAA";
      content = ipv6;
      comment = "Tailscale IPv6 - `tailscale whois ${ipv6}`";
    };
  };
}
