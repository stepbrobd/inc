{ lib, config, ... }:

let
  cfg = config.services.as10779;
in
{
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
        local = lib.blueprint.hosts.highline.ipam.interface;
        primary = lib.blueprint.hosts.highline.interface;
      };
      ipv4.addresses = [
        "${lib.blueprint.hosts.highline.ipam.ipv4}/32" # unicast
        "23.161.104.17/32" # personal site anycast
        # "44.32.189.0/24" # 44net anycast test
      ];
      ipv6.addresses = [
        "${lib.blueprint.hosts.highline.ipam.ipv6}/128" # unicast
        "2602:f590::23:161:104:17/128" # personal site anycast
      ];
    };

    router = {
      secret = config.sops.secrets.bgp.path;
      source = { inherit (lib.blueprint.hosts.highline) ipv4 ipv6; };
      static =
        let
          option = "reject";
          # lib.trim ''
          #   reject {
          #       bgp_large_community.add((21700, 101, 2)); # customer route
          #       bgp_large_community.add((21700, 102, 840)); # source US
          #       bgp_large_community.add((21700, 103, 1)); # source NYC
          #     }
          # '';
        in
        {
          ipv4.routes = [
            { inherit option; prefix = "23.161.104.0/24"; }
            # { inherit option; prefix = "44.32.189.0/24"; } # stop announcing 44net for now
            { inherit option; prefix = "192.104.136.0/24"; }
          ];
          ipv6.routes = [
            { inherit option; prefix = "2602:f590::/36"; }
          ] ++ lib.blueprint.prefixes.experimental.ipv6;
        };
      sessions = [
        {
          name = "neptune";
          password = null;
          type = { ipv4 = "direct"; ipv6 = "multihop"; };
          neighbor = {
            asn = 21700;
            ipv4 = "172.82.22.129";
            ipv6 = "2602:fe2e:4:80::1";
          };
          import = {
            ipv4 = "import filter ${cfg.router.rpki.ipv4.filter};";
            ipv6 = "import filter ${cfg.router.rpki.ipv6.filter};";
          };
          export = {
            ipv4 = ''export where proto = "${cfg.router.static.ipv4.name}";'';
            ipv6 = ''export where proto = "${cfg.router.static.ipv6.name}";'';
          };
        }
        {
          name = "bgptools";
          password = null;
          type = { ipv4 = "disabled"; ipv6 = "multihop"; };
          mp = "v4 over v6";
          neighbor = {
            asn = 212232;
            ipv4 = null;
            ipv6 = "2a0c:2f07:9459::b14";
          };
          import = {
            ipv4 = "import none;";
            ipv6 = "import none;";
          };
          export = {
            ipv4 = "export all;";
            ipv6 = "export all;";
          };
        }
      ];
    };
  };
}
