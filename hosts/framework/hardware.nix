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
    "usb_storage"
    "sd_mod"
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
  # battery charge thresholds not needed after firmware update
  # services.tlp.settings = {
  #   START_CHARGE_THRESH_BAT0 = 70;
  #   STOP_CHARGE_THRESH_BAT0 = 75;
  #   START_CHARGE_THRESH_BAT1 = 70;
  #   STOP_CHARGE_THRESH_BAT1 = 75;
  # };

  # bluetooth
  hardware.bluetooth.enable = true;

  # fingerprint
  services.fprintd = {
    enable = true;
    # https://knowledgebase.frame.work/en_us/updating-fingerprint-reader-firmware-on-linux-for-13th-gen-and-amd-ryzen-7040-series-laptops-HJrvxv_za
    # tod.enable = true;
    # tod.driver = pkgs.libfprint-2-tod1-goodix;
  };

  system.stateVersion = "25.05";
}
