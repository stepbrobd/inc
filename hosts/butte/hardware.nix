{ lib, modulesPath, ... }:

{
  imports = [ "${modulesPath}/profiles/qemu-guest.nix" ];
  services.qemuGuest.enable = true;

  boot.loader.grub.device = "/dev/vda";
  boot.initrd.kernelModules = [ "nvme" ];
  boot.initrd.availableKernelModules = [
    "ata_piix"
    "uhci_hcd"
    "vmw_pvscsi"
    "xen_blkfront"
  ];

  fileSystems."/" = { device = "/dev/vda1"; fsType = "ext4"; };

  networking = {
    defaultGateway = {
      address = "185.234.100.254";
      interface = "eth0";
    };
    defaultGateway6 = {
      address = "fe80::1";
      interface = "eth0";
    };
    dhcpcd.enable = false;
    usePredictableInterfaceNames = lib.mkForce false;
    interfaces.eth0 = {
      ipv4.addresses = [
        { address = "185.234.100.120"; prefixLength = 24; }
      ];
      ipv6.addresses = [
        { address = "2a07:8dc0:1c:0:48:f1ff:febe:1c6"; prefixLength = 128; }
        { address = "fe80::248:f1ff:febe:1c6"; prefixLength = 64; }
      ];
      ipv4.routes = [
        { address = "185.234.100.254"; prefixLength = 32; }
        { address = "172.16.0.121"; via = "185.234.100.254"; prefixLength = 32; }
        { address = "172.16.0.122"; via = "185.234.100.254"; prefixLength = 32; }
      ];
      ipv6.routes = [
        { address = "fe80::1"; prefixLength = 128; }
        { address = "2a0d:e680:0::b:1"; via = "fe80::1"; prefixLength = 128; }
        { address = "2a0d:e680:0::b:2"; via = "fe80::1"; prefixLength = 128; }
        { address = "2a07:8dc0:1c::"; via = "fe80::1"; prefixLength = 48; }
      ];
    };
  };

  services.udev.extraRules = ''
    ATTR{address}=="00:48:f1:be:01:c6", NAME="eth0"
  '';

  system.stateVersion = "25.05";
}
