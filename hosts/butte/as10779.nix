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
        local = lib.blueprint.hosts.butte.ipam.interface;
        primary = lib.blueprint.hosts.butte.interface;
      };
      ipv4.addresses = [
        "${lib.blueprint.hosts.butte.ipam.ipv4}/32" # unicast
        "23.161.104.17/32" # personal site anycast
        # "44.32.189.0/24" # 44net anycast test
      ];
      ipv6.addresses = [
        "${lib.blueprint.hosts.butte.ipam.ipv6}/128" # unicast
        "2602:f590::23:161:104:17/128" # personal site anycast
      ];
    };

    router = {
      secret = config.sops.secrets.bgp.path;
      source = { inherit (lib.blueprint.hosts.butte) ipv4 ipv6; };
      static =
        let
          # option = "reject";
          # https://github.com/virtuasys/as35661: 35661:<action><loc>:<target>
          # action 1-3 = prepend Nx, 9 = dont export, loc 999 = all PoPs
          # target: ASN, 1 = all transit, 2 = all IX peers
          # prepend 1x toward all transit (Cogent/Arelion/GTT/aurologic/Eranium/HOPUS)
          # if needed: (35661, 9999, 6939) + (35661, 9999, 174) dont export HE/Cogent
          option = lib.trim ''
            reject {
                bgp_large_community.add((35661, 1999, 1));
              }
          '';
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
          name = "virtua1";
          password = "PASS_AS35661";
          type = { ipv4 = "multihop"; ipv6 = "multihop"; };
          neighbor = {
            asn = 35661;
            ipv4 = "172.16.0.121";
            ipv6 = "2a0d:e680:0::b:1";
          };
          import = {
            ipv4 = "import none;";
            ipv6 = "import none;";
          };
          export = {
            ipv4 = ''export where proto = "${cfg.router.static.ipv4.name}";'';
            ipv6 = ''export where proto = "${cfg.router.static.ipv6.name}";'';
          };
        }
        {
          name = "virtua2";
          password = "PASS_AS35661";
          type = { ipv4 = "multihop"; ipv6 = "multihop"; };
          neighbor = {
            asn = 35661;
            ipv4 = "172.16.0.122";
            ipv6 = "2a0d:e680:0::b:2";
          };
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
