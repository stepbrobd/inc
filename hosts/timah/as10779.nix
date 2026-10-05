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
        local = lib.blueprint.hosts.timah.ipam.interface;
        primary = lib.blueprint.hosts.timah.interface;
      };
      ipv4.addresses = [
        "${lib.blueprint.hosts.timah.ipam.ipv4}/32" # unicast
        "23.161.104.17/32" # personal site anycast
        # "44.32.189.0/24" # 44net anycast test
      ];
      ipv6.addresses = [
        "${lib.blueprint.hosts.timah.ipam.ipv6}/128" # unicast
        "2602:f590::23:161:104:17/128" # personal site anycast
      ];
    };

    router = {
      secret = config.sops.secrets.bgp.path;
      source = { inherit (lib.blueprint.hosts.timah) ipv4 ipv6; };
      static =
        let
          # option = "reject";
          # https://docs.misaka.io/network/communities
          # (rt, 65009, ASN) dont announce, (rt, 65001-65003, ASN) prepend Nx
          # GSL is the transit and hauls its whole footprint to a customer route
          # if needed (rt, 65009, 13335) cloudflare returns non EU traffic via here
          option = lib.trim ''
            reject {
                bgp_ext_community.add((rt, 65009, 137409)); # dont announce to GSL
              }
          '';
        in
        {
          ipv4.routes = [
            { inherit option; prefix = "23.161.104.0/24"; }
            # { inherit option; prefix = "44.32.189.0/24"; } # stop announcing 44net for now
            { inherit option; prefix = "192.104.136.0/24"; }
            { inherit option; prefix = "204.115.20.0/23"; }
          ];
          ipv6.routes = [
            { inherit option; prefix = "2602:f590::/36"; }
          ] ++ lib.blueprint.prefixes.experimental.ipv6;
        };
      sessions = [
        {
          name = "misaka";
          password = null;
          type = { ipv4 = "multihop"; ipv6 = "multihop"; };
          neighbor = {
            asn = 57695;
            ipv4 = "100.100.0.0";
            ipv6 = "2a0b:4342:ffff::";
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
