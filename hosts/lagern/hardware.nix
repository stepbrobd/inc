{ modulesPath, ... }:

{
  imports = [
    ./disko.nix
    "${modulesPath}/virtualisation/amazon-image.nix"
  ];

  hardware.facter.reportPath = ./facter.json;

  fileSystems."/".autoResize = true;

  system.stateVersion = "25.05";
}
