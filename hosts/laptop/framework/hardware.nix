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

  # power
  # battery reporting (needed by noctalia battery widget)
  services.upower.enable = true;
  services.tlp = {
    enable = true;
    settings = {
      # not needed after firmware update
      # run `ls /sys/class/power_supply` to check available power supplies
      # run `tlp fullcharge` to charge to 100%
      # START_CHARGE_THRESH_BAT0 = 70;
      # STOP_CHARGE_THRESH_BAT0 = 75;
      # START_CHARGE_THRESH_BAT1 = 70;
      # STOP_CHARGE_THRESH_BAT1 = 75;
      CPU_SCALING_GOVERNOR_ON_AC = "powersave";
      CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
      CPU_ENERGY_PERF_POLICY_ON_AC = "performance";
      CPU_ENERGY_PERF_POLICY_ON_BAT = "balance_power";
    };
  };
  services.thermald.enable = true;
  powerManagement = {
    enable = true;
    powertop.enable = true;
  };
  # services.auto-cpufreq = {
  #   enable = true;
  #   # governor: powersave, ondemand, performance
  #   # turbo: never, always, auto
  #   settings = {
  #     battery = {
  #       governor = "powersave";
  #       turbo = "never";
  #     };
  #     charger = {
  #       governor = "performance";
  #       turbo = "auto";
  #     };
  #   };
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
