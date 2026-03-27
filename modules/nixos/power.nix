{
  services.upower.enable = true;

  services.tlp = {
    enable = true;
    settings = {
      # max performance for dev on ac
      CPU_SCALING_GOVERNOR_ON_AC = "performance";
      CPU_ENERGY_PERF_POLICY_ON_AC = "performance";
      CPU_BOOST_ON_AC = 1;

      # efficient on bat
      CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
      CPU_ENERGY_PERF_POLICY_ON_BAT = "balance_performance";
      CPU_BOOST_ON_BAT = 0;
      CPU_HWP_DYN_BOOST_ON_BAT = 0;

      # PCIe ASPM on battery for deep package idle
      PCIE_ASPM_ON_AC = "default";
      PCIE_ASPM_ON_BAT = "powersupersave";

      # runtime PM
      RUNTIME_PM_ON_AC = "on";
      RUNTIME_PM_ON_BAT = "auto";
    };
  };

  services.thermald.enable = true;

  powerManagement = {
    enable = true;
    powertop.enable = true;
  };

  # keep awake with lid closed on ac
  services.logind.lidSwitchExternalPower = "ignore";
}
