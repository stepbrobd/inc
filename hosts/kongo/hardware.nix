{ modulesPath, ... }:

{
  imports = [ "${modulesPath}/profiles/qemu-guest.nix" ];
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
    "vmw_pvscsi"
    "xen_blkfront"
  ];

  fileSystems = {
    "/" = { device = "/dev/vda2"; fsType = "ext4"; };
    "/boot" = { device = "/dev/disk/by-uuid/E779-7666"; fsType = "vfat"; };
  };

  system.stateVersion = "25.05";
}
