{ lib, modulesPath, ... }:

{
  imports = [
    ./disko.nix
    "${modulesPath}/profiles/qemu-guest.nix"
  ];
  services.qemuGuest.enable = true;

  hardware.facter.reportPath = ./facter.json;
  hardware.facter.detected.graphics.enable = false;

  boot.loader.grub.device = "/dev/sda";

  zramSwap.enable = lib.mkForce false;

  networking = {
    defaultGateway = {
      address = "185.194.53.1";
      interface = "ens18";
    };
    defaultGateway6 = {
      address = "2a04:6f00:4::1";
      interface = "ens18";
    };
    dhcpcd.enable = false;
    usePredictableInterfaceNames = lib.mkForce true;
    interfaces.ens18 = {
      ipv4.addresses = [{ address = "185.194.53.29"; prefixLength = 24; }];
      ipv6.addresses = [
        { address = "2a04:6f00:4::a5"; prefixLength = 48; }
        { address = "fe80::722e:d3ff:fe7b:b1ba"; prefixLength = 64; }
      ];
      ipv4.routes = [{ address = "185.194.53.1"; prefixLength = 32; }];
      ipv6.routes = [{ address = "2a04:6f00:4::1"; prefixLength = 128; }];
    };
  };

  services.udev.extraRules = ''
    ATTR{address}=="70:2e:d3:7b:b1:ba", NAME="ens18"
  '';

  system.stateVersion = "25.05";
}
