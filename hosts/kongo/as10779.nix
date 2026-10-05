{ lib, config, ... }:

let
  cfg = config.services.as10779;
in
{
  imports = [ ./homenoc.nix ];

  sops.secrets.bgp = {
    sopsFile = ./secrets.yaml;
    mode = "440";
    owner = config.systemd.services.bird.serviceConfig.User;
    group = config.systemd.services.bird.serviceConfig.Group;
    reloadUnits = [ config.systemd.services.bird.name ];
  };

  services.as10779 = {
    enable = true;

    local = {
      hostname = config.networking.hostName;
      interface = {
        local = lib.blueprint.hosts.kongo.ipam.interface;
        primary = lib.blueprint.hosts.kongo.interface;
      };
      ipv4.addresses = [
        "${lib.blueprint.hosts.kongo.ipam.ipv4}/32" # unicast
        "23.161.104.17/32" # personal site anycast
        # "44.32.189.0/24" # 44net anycast test
      ];
      ipv6.addresses = [
        "${lib.blueprint.hosts.kongo.ipam.ipv6}/128" # unicast
        "2602:f590::23:161:104:17/128" # personal site anycast
      ];
    };

    router = {
      secret = config.sops.secrets.bgp.path;
      source = { inherit (lib.blueprint.hosts.kongo) ipv4 ipv6; };
      static =
        let
          # option = "reject";
          option = lib.trim ''
            reject {
                # prefer jp local
                bgp_large_community.add((20473, 6009, 2914));  # NTT
                bgp_large_community.add((20473, 6009, 17676)); # SoftBank
                # prepend 1x
                bgp_large_community.add((20473, 6001, 3320)); # DTAG
                # prepend 2x
                bgp_large_community.add((20473, 6002, 701));  # Verizon
                bgp_large_community.add((20473, 6002, 1299)); # Arelion
                bgp_large_community.add((20473, 6002, 6830)); # Liberty Global
                # prepend 3x
                bgp_large_community.add((20473, 6003, 174));  # Cogent
                bgp_large_community.add((20473, 6003, 1221)); # Telstra
                bgp_large_community.add((20473, 6003, 3356)); # Level3
                bgp_large_community.add((20473, 6003, 4826)); # Vocus
                # https://www.homenoc.ad.jp/tech/community/
                # BIGLOBE hauls singapore to osaka on this customer route
                # prepend 1x
                bgp_large_community.add((59105, 1021, 2518)); # BIGLOBE
              }
          '';
        in
        {
          ipv4.routes = [
            { inherit option; prefix = "23.161.104.0/24"; }
            # { inherit option; prefix = "44.32.189.0/24"; } # stop announcing 44net for now
            { inherit option; prefix = "192.104.136.0/24"; }
            { inherit option; prefix = "204.115.20.0/23"; }
            # https://skym.fi/blog/2020/07/vultr-trouble/
            # { prefix = "169.254.169.254/32"; option = "via ${lib.blueprint.hosts.kongo.ipv4}"; }
          ];
          ipv6.routes = [
            { inherit option; prefix = "2602:f590::/36"; }
            # https://skym.fi/blog/2020/07/vultr-trouble/
            # { prefix = "2001:19f0:ffff::1/128"; option = "via ${lib.blueprint.hosts.kongo.ipv6}"; }
          ] ++ lib.blueprint.prefixes.experimental.ipv6;
        };
      # nothing bird learns belongs in the FIB
      # both sessions are import none and the default arrives via RA/DHCP
      kernel = {
        ipv4.export = "export none;";
        ipv6.export = "export none;";
      };
      sessions = [
        {
          name = "vultr";
          password = "PASS_AS64515";
          type = { ipv4 = "multihop"; ipv6 = "multihop"; };
          neighbor = {
            asn = 64515;
            ipv4 = "169.254.169.254";
            ipv6 = "2001:19f0:ffff::1";
          };
          import = {
            ipv4 = "import none;";
            ipv6 = "import none;";
          };
          export = {
            ipv4 = ''export filter {
              if proto != "${cfg.router.static.ipv4.name}" then reject;
              if net = 169.254.169.254/32 then reject;
              accept;
            };'';
            ipv6 = ''export filter {
              if proto != "${cfg.router.static.ipv6.name}" then reject;
              if net = 2001:19f0:ffff::1/128 then reject;
              accept;
            };'';
          };
        }
        {
          # see ./homenoc.nix
          name = "homenoc";
          password = null;
          type = { ipv4 = "direct"; ipv6 = "direct"; };
          source = { ipv4 = "103.247.181.67"; ipv6 = "2403:bd80:bbc0:5308::2"; };
          neighbor = {
            asn = 59105;
            ipv4 = "103.247.181.66";
            ipv6 = "2403:bd80:bbc0:5308::1";
          };
          # ingress only
          import = {
            ipv4 = "import none;";
            ipv6 = "import none;";
          };
          export = {
            ipv4 = ''export where proto = "${cfg.router.static.ipv4.name}";'';
            ipv6 = ''export where proto = "${cfg.router.static.ipv6.name}";'';
          };
        }
      ];
    };
  };
}
