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
        local = lib.blueprint.hosts.toompea.ipam.interface;
        primary = lib.blueprint.hosts.toompea.interface;
      };
      ipv4.addresses = [
        "${lib.blueprint.hosts.toompea.ipam.ipv4}/32" # unicast
        "23.161.104.17/32" # personal site anycast
        # "44.32.189.0/24" # 44net anycast test
      ];
      ipv6.addresses = [
        "${lib.blueprint.hosts.toompea.ipam.ipv6}/128" # unicast
        "2602:f590::23:161:104:17/128" # personal site anycast
      ];
    };

    router = {
      secret = config.sops.secrets.bgp.path;
      source = { inherit (lib.blueprint.hosts.toompea) ipv4 ipv6; };
      static =
        let
          option = "reject";
          # lib.trim ''
          #   reject {
          #       # prepend 1x
          #       bgp_community.add((3204, 1101)); # xTom
          #       # dont announce
          #       bgp_community.add((3204, 1700)); # Liberty Global
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
      kernel = {
        ipv4.export = ''export where proto = "${cfg.router.static.ipv4.name}";'';
        ipv6.export = ''export where proto = "${cfg.router.static.ipv6.name}";'';
      };
      # upstream bgp gateway differs from main interface gateway
      outboundGateway = {
        ipv4 = "185.194.53.4";
        ipv6 = "2a04:6f00:4::4";
      };
      sessions = [
        {
          name = "xtom";
          password = "PASS_AS3204";
          type = { ipv4 = "direct"; ipv6 = "direct"; };
          neighbor = {
            asn = 3204;
            ipv4 = "185.194.53.4";
            ipv6 = "2a04:6f00:4::4";
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
            ipv6 = "2a0c:2f07:9459::b19";
          };
          addpath = "tx";
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
