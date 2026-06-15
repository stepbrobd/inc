{ lib, modulesPath, ... }:

{
  imports = [
    ./disko.nix
    "${modulesPath}/profiles/qemu-guest.nix"
  ];
  services.qemuGuest.enable = true;

  hardware.facter.reportPath = ./facter.json;

  boot.loader.grub.device = "/dev/sda";

  networking = {
    defaultGateway = {
      address = "100.127.255.1";
      interface = "ens3";
    };
    defaultGateway6 = {
      address = "fe80::f816:3eff:feb7:d7a1";
      interface = "ens4";
    };
    dhcpcd.enable = false;
    usePredictableInterfaceNames = lib.mkForce true;
    interfaces.ens3 = {
      ipv4.addresses = [{ address = "100.127.255.25"; prefixLength = 24; }];
      ipv4.routes = [{ address = "100.127.255.1"; prefixLength = 32; }];
    };
    interfaces.ens4.ipv6.addresses = [
      { address = "2001:808:3:60d:f816:3eff:fe3a:8fd6"; prefixLength = 64; }
      { address = "fe80::f816:3eff:fe3a:8fd6"; prefixLength = 64; }
    ];
  };

  services.udev.extraRules = ''
    ATTR{address}=="fa:16:3e:ca:b3:23", NAME="ens3"
    ATTR{address}=="fa:16:3e:3a:8f:d6", NAME="ens4"
  '';

  networking.ranet.interfaces = [ "ens3" "ens4" ];
  networking.ranet.settings.endpoints = lib.map
    (ep: if ep.address_family == "ip4" then ep // { address = null; } else ep)
    lib.blueprint.hosts.morasko.ranet.endpoints;

  system.stateVersion = "26.11";
}
