{ lib, modulesPath, ... }:

{
  imports = [ "${modulesPath}/profiles/qemu-guest.nix" ];

  boot.loader.grub.device = "/dev/sda";
  boot.initrd.availableKernelModules = [
    "ata_piix"
    "uhci_hcd"
    "xen_blkfront"
    "vmw_pvscsi"
  ];
  boot.initrd.kernelModules = [ "nvme" ];
  fileSystems."/" = {
    device = "/dev/sda1";
    fsType = "ext4";
  };

  networking = {
    defaultGateway = {
      address = "172.31.1.1";
      interface = "eth0";
    };
    defaultGateway6 = {
      address = "fe80::1";
      interface = "eth0";
    };
    dhcpcd.enable = false;
    usePredictableInterfaceNames = lib.mkForce false;
    interfaces.eth0 = {
      ipv4.addresses = [{ address = "23.88.126.45"; prefixLength = 32; }];
      ipv6.addresses = [
        { address = "2a01:4f8:c17:4b75::1"; prefixLength = 64; }
        { address = "fe80::9400:3ff:fe8f:3670"; prefixLength = 64; }
      ];
      ipv4.routes = [{ address = "172.31.1.1"; prefixLength = 32; }];
      ipv6.routes = [{ address = "fe80::1"; prefixLength = 128; }];
    };
  };

  services.udev.extraRules = ''
    ATTR{address}=="96:00:03:8f:36:70", NAME="eth0"
  '';

  system.stateVersion = "25.05";
}
