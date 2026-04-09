{ lib, modulesPath, ... }:

{
  imports = [ "${modulesPath}/profiles/qemu-guest.nix" ];
  services.qemuGuest.enable = true;

  hardware.facter.reportPath = ./facter.json;

  boot.loader.grub.device = "/dev/sda";

  networking = {
    defaultGateway = {
      address = "45.159.98.129";
      interface = "ens3";
    };
    defaultGateway6 = {
      address = "2a00:dd80:40:100::1";
      interface = "ens3";
    };
    dhcpcd.enable = false;
    usePredictableInterfaceNames = lib.mkForce true;
    interfaces.ens3 = {
      ipv4.addresses = [{ address = "45.159.98.222"; prefixLength = 25; }];
      ipv6.addresses = [
        { address = "2a00:dd80:40:100::6f"; prefixLength = 64; }
        { address = "fe80::216:3eff:fe5b:ca29"; prefixLength = 64; }
      ];
      ipv4.routes = [{ address = "45.159.98.129"; prefixLength = 32; }];
      ipv6.routes = [{ address = "2a00:dd80:40:100::1"; prefixLength = 128; }];
    };
  };

  services.udev.extraRules = ''
    ATTR{address}=="00:16:3e:5b:ca:29", NAME="ens3"
  '';

  system.stateVersion = "26.05";
}
