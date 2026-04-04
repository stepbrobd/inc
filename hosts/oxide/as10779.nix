{ config, lib, ... }:

{
  services.as10779 = {
    enable = true;
    router.exit = false;

    local = {
      hostname = config.networking.hostName;
      interface = {
        local = lib.blueprint.hosts.oxide.ipam.interface;
        primary = lib.blueprint.hosts.oxide.interface;
      };
      ipv4.addresses = [ "${lib.blueprint.hosts.oxide.ipam.ipv4}/32" ];
      ipv6.addresses = [ "${lib.blueprint.hosts.oxide.ipam.ipv6}/128" ];
    };

    router.static = {
      ipv4.routes = [{ option = "reject"; prefix = "23.161.104.0/24"; }];
      ipv6.routes = [{ option = "reject"; prefix = "2602:f590::/36"; }];
    };
  };
}
