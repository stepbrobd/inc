{ config, lib, pkgs, ... }:

{
  environment.systemPackages = [ pkgs.gravity.vpn ];

  # add this to allow strongswan bind to wireless and wired interfaces
  # to ensure tunnes dont break if switch from wired to wireless
  # networking.ranet.interfaces = [ "wlp170s0" "eth0" ];

  services.as10779 = {
    enable = true;
    router.exit = false;
    router.id = lib.blueprint.hosts.framework.ipam.ipv4;

    local = {
      hostname = config.networking.hostName;
      interface = {
        local = lib.blueprint.hosts.framework.ipam.interface;
        primary = lib.blueprint.hosts.framework.interface;
      };
      ipv4.addresses = [ "${lib.blueprint.hosts.framework.ipam.ipv4}/32" ];
      ipv6.addresses = [ "${lib.blueprint.hosts.framework.ipam.ipv6}/128" ];
    };

    router.static = {
      ipv4.routes = [{ option = "reject"; prefix = "${lib.blueprint.hosts.framework.ipam.ipv4}/32"; }];
      ipv6.routes = [{ option = "reject"; prefix = "${lib.blueprint.hosts.framework.ipam.ipv6}/128"; }];
    };
  };
}
