{ lib, modulesPath, ... }:

{
  imports = [ "${modulesPath}/profiles/qemu-guest.nix" ];
  services.qemuGuest.enable = true;

  boot.loader.grub.device = "/dev/sda";
  boot.initrd.kernelModules = [ "nvme" ];
  boot.initrd.availableKernelModules = [
    "ata_piix"
    "uhci_hcd"
    "xen_blkfront"
    "vmw_pvscsi"
  ];

  fileSystems."/" = {
    device = "/dev/sda2";
    fsType = "ext4";
  };

  networking = {
    defaultGateway = {
      address = "209.182.234.1";
      interface = "enp3s0";
    };
    defaultGateway6 = {
      address = "2602:ff16:14::1";
      interface = "enp3s0";
    };
    dhcpcd.enable = false;
    usePredictableInterfaceNames = lib.mkForce true;
    interfaces.enp3s0 = {
      ipv4.addresses = [{ address = "209.182.234.194"; prefixLength = 24; }];
      ipv6.addresses = [
        { address = "2602:ff16:14:0:1:56:0:1"; prefixLength = 64; }
        { address = "fe80::5054:25ff:fe46:aa1c"; prefixLength = 64; }
      ];
      ipv4.routes = [{ address = "209.182.234.1"; prefixLength = 32; }];
      ipv6.routes = [{ address = "2602:ff16:14::1"; prefixLength = 128; }];
    };
  };

  services.udev.extraRules = ''
    ATTR{address}=="52:54:25:46:aa:1c", NAME="enp3s0"
  '';

  system.stateVersion = "25.05";
}
