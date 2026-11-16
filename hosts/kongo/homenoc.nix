{ lib, ... }:

let
  host = lib.blueprint.hosts.kongo;

  interface = "homenoc";

  # AS59105 POP03 ER04transit (over IPIP tunnel)
  remote = "2405:6580:9fc0:9700::face";

  # see dashboard
  mtu = 1452;
in
{
  systemd.network = {
    netdevs."45-${interface}" = {
      netdevConfig = {
        Kind = "ip6tnl";
        Name = interface;
        MTUBytes = toString mtu;
      };

      tunnelConfig = {
        Local = host.ipv6;
        Remote = remote;
        Independent = true;

        # both IPv4 (proto 4) and IPv6 (proto 41)
        Mode = "any";

        # linux defaults to encaplimit 4
        # which prepends RFC 2473 tunnel encapsulation limit destination option
        # so the outer next header becomes 60 instead of 4/41
        # junos IPIP-NULL discards those which kept their ip-1/0/0.5 at "Input packets: 0"
        EncapsulationLimit = "none";
      };
    };

    networks."45-${interface}" = {
      matchConfig.Name = interface;
      address = [
        "103.247.181.67/31"
        "2403:bd80:bbc0:5308::2/64"
      ];
      networkConfig.LinkLocalAddressing = "no";
    };
  };

  # outer packets leave with node's own provider address as source
  # the outbound masquerade chain matches them and binds a NAT
  # to the flow conntrack keys proto 4/41 on addresses alone (these carry no ports)
  # a stale binding blackholes every IPv4-in-IPv6 packet until conntrack is flushed
  # transit tunnel packets have no business being tracked at all
  networking.nftables.tables.homenoc = {
    family = "inet";
    content = ''
      chain prerouting {
        type filter hook prerouting priority raw; policy accept;
        ip6 saddr ${remote} ip6 daddr ${host.ipv6} meta l4proto { 4, 41 } notrack
      }

      chain output {
        type filter hook output priority raw; policy accept;
        ip6 daddr ${remote} ip6 saddr ${host.ipv6} meta l4proto { 4, 41 } notrack
      }
    '';
  };

  # untracked packets skip the established/related shortcut in the input chain
  # so the encapsulated traffic has to be admitted on its own
  networking.firewall.extraInputRules = ''
    ip6 saddr ${remote} meta l4proto { 4, 41 } accept
  '';
}
