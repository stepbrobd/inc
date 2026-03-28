{ lib, modulesPath, ... }:

{
  imports = [
    ./disko.nix
    "${modulesPath}/profiles/qemu-guest.nix"
  ];
  services.qemuGuest.enable = true;

  boot.loader.grub = {
    efiSupport = true;
    efiInstallAsRemovable = true;
    device = "nodev";
  };

  boot.initrd.kernelModules = [ "nvme" ];
  boot.initrd.availableKernelModules = [
    "ata_piix"
    "uhci_hcd"
    "xen_blkfront"
    "vmw_pvscsi"
  ];

  zramSwap.enable = lib.mkForce false;

  networking = {
    defaultGateway = {
      address = "172.82.22.129";
      interface = "ens3";
    };
    defaultGateway6 = {
      address = "fe80::216:3eff:fe71:5ecb";
      interface = "ens3";
    };
    dhcpcd.enable = false;
    usePredictableInterfaceNames = lib.mkForce true;
    interfaces.ens3 = {
      ipv4.addresses = [{ address = "172.82.22.183"; prefixLength = 26; }];
      ipv6.addresses = [
        { address = "2602:fe2e:4:b2:fd:87ff:fe11:53cb"; prefixLength = 64; }
      ];
      ipv4.routes = [{ address = "172.82.22.129"; prefixLength = 32; }];
      ipv6.routes = [{ address = "fe80::216:3eff:fe71:5ecb"; prefixLength = 128; }];
    };
  };

  services.udev.extraRules = ''
    ATTR{address}=="02:fd:87:11:53:cb", NAME="ens3"
  '';

  system.stateVersion = "25.05";
}
