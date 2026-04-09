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
      address = "208.111.40.1";
      interface = "ens3";
    };
    defaultGateway6 = {
      address = "2607:f740:c::1";
      interface = "ens3";
    };
    dhcpcd.enable = false;
    usePredictableInterfaceNames = lib.mkForce true;
    interfaces.ens3 = {
      ipv4.addresses = [{ address = "208.111.40.54"; prefixLength = 24; }];
      ipv6.addresses = [
        { address = "2607:f740:c::a49"; prefixLength = 64; }
        { address = "fe80::216:3eff:fe13:68e1"; prefixLength = 64; }
      ];
      ipv4.routes = [{ address = "208.111.40.1"; prefixLength = 32; }];
      ipv6.routes = [{ address = "2607:f740:c::1"; prefixLength = 128; }];
    };
  };

  services.udev.extraRules = ''
    ATTR{address}=="00:16:3e:13:68:e1", NAME="ens3"
  '';

  system.stateVersion = "26.05";
}
