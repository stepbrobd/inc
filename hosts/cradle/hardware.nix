{ lib, modulesPath, ... }:

{
  imports = [ "${modulesPath}/profiles/qemu-guest.nix" ];
  services.qemuGuest.enable = true;

  hardware.facter.reportPath = ./facter.json;

  boot.loader.grub.device = "/dev/sda";

  networking = {
    defaultGateway = {
      address = "43.245.48.1";
      interface = "ens3";
    };
    defaultGateway6 = {
      address = "2403:2500:9000:1::1";
      interface = "ens3";
    };
    dhcpcd.enable = false;
    usePredictableInterfaceNames = lib.mkForce true;
    interfaces.ens3 = {
      ipv4.addresses = [{ address = "43.245.48.187"; prefixLength = 24; }];
      ipv6.addresses = [
        { address = "2403:2500:9000:1::dc6"; prefixLength = 64; }
        { address = "fe80::216:3eff:fe1a:ef24"; prefixLength = 64; }
      ];
      ipv4.routes = [{ address = "43.245.48.1"; prefixLength = 32; }];
      ipv6.routes = [{ address = "2403:2500:9000:1::1"; prefixLength = 128; }];
    };
  };

  services.udev.extraRules = ''
    ATTR{address}=="00:16:3e:1a:ef:24", NAME="ens3"
  '';

  system.stateVersion = "26.05";
}
