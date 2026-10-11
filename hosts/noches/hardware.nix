{ pkgs, ... }:

{
  imports = [ ./disko.nix ];

  hardware.facter.reportPath = ./facter.json;

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # hpwdt nmi comes 9s before expiry
  # before systemd ping at half of srvos 15s
  # which causes panic
  boot.kernelParams = [ "hpwdt.pretimeout=0" ];

  boot.kernelModules = [ "sg" ];
  environment.systemPackages = [ pkgs.ssacli ];

  system.stateVersion = "26.11";
}
