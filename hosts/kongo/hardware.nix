{ modulesPath, ... }:

{
  imports = [
    ./disko.nix
    "${modulesPath}/profiles/qemu-guest.nix"
  ];
  services.qemuGuest.enable = true;

  hardware.facter.reportPath = ./facter.json;
  hardware.facter.detected.graphics.enable = false;
  # vultr kvm exposes hyper-v cpuid leaves without a vmbus
  hardware.facter.detected.virtualisation.hyperv.enable = false;

  srvos.boot.consoles = [ "tty0" ];

  boot.loader.grub = {
    efiSupport = true;
    efiInstallAsRemovable = true;
    device = "nodev";
  };

  system.stateVersion = "25.05";
}
