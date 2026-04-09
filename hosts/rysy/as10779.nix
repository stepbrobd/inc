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
        local = lib.blueprint.hosts.rysy.ipam.interface;
        primary = lib.blueprint.hosts.rysy.interface;
      };
      ipv4.addresses = [
        "${lib.blueprint.hosts.rysy.ipam.ipv4}/32" # unicast
        "23.161.104.17/32" # personal site anycast
      ];
      ipv6.addresses = [
        "${lib.blueprint.hosts.rysy.ipam.ipv6}/128" # unicast
        "2602:f590::23:161:104:17/128" # personal site anycast
      ];
    };

    router = {
      secret = config.sops.secrets.bgp.path;
      source = { inherit (lib.blueprint.hosts.rysy) ipv4 ipv6; };
      static =
        let
          option = "reject";
        in
        {
          ipv4.routes = [
            { inherit option; prefix = "23.161.104.0/24"; }
            { inherit option; prefix = "192.104.136.0/24"; }
          ];
          ipv6.routes = [
            { inherit option; prefix = "2602:f590::/36"; }
          ] ++ lib.blueprint.prefixes.experimental.ipv6;
        };
      sessions = [
        {
          name = "netactuate";
          password = null;
          type = { ipv4 = "direct"; ipv6 = "direct"; };
          neighbor = {
            asn = 36236;
            ipv4 = "45.159.98.175";
            ipv6 = "2a00:dd80:40:100::312";
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
      ];
    };
  };
}
