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
      address = "148.163.220.1";
      interface = "ens3";
    };
    defaultGateway6 = {
      address = "2607:f740:1::1";
      interface = "ens3";
    };
    dhcpcd.enable = false;
    usePredictableInterfaceNames = lib.mkForce true;
    interfaces.ens3 = {
      ipv4.addresses = [{ address = "148.163.220.57"; prefixLength = 24; }];
      ipv6.addresses = [
        { address = "2607:f740:1::7f"; prefixLength = 64; }
        { address = "fe80::216:3eff:fe21:24ae"; prefixLength = 64; }
      ];
      ipv4.routes = [{ address = "148.163.220.1"; prefixLength = 32; }];
      ipv6.routes = [{ address = "2607:f740:1::1"; prefixLength = 128; }];
    };
  };

  services.udev.extraRules = ''
    ATTR{address}=="00:16:3e:21:24:ae", NAME="ens3"
  '';

  system.stateVersion = "26.05";
}
