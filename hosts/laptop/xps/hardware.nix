{ lib, ... }:

{
  hardware.enableAllFirmware = lib.mkDefault true;
  services.fwupd.enable = true;

  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  boot.initrd.kernelModules = [ ];
  boot.initrd.availableKernelModules = [
    "xhci_pci"
    "thunderbolt"
    "nvme"
    "vmd"
    "usb_storage"
    "sd_mod"
    "rtsx_pci_sdmmc"
  ];

  imports = [ ./disko.nix ];

  boot.bootspec.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.systemd-boot.enable = lib.mkForce false;
  boot.lanzaboote = {
    enable = true;
    pkiBundle = "/var/lib/sbctl";
    settings.timeout = 0;
  };
  security.tpm2 = {
    enable = true;
    tctiEnvironment.enable = true;
  };

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  # thunderbolt
  services.hardware.bolt.enable = true;

  # power (common settings in modules/nixos/power.nix)
  # run `tlp fullcharge` to charge to 100%
  services.tlp.settings = {
    START_CHARGE_THRESH_BAT0 = 70;
    STOP_CHARGE_THRESH_BAT0 = 75;
    START_CHARGE_THRESH_BAT1 = 70;
    STOP_CHARGE_THRESH_BAT1 = 75;
  };

  # bluetooth
  hardware.bluetooth.enable = true;

  system.stateVersion = "25.05";
}
