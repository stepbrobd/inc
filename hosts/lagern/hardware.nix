{ modulesPath, ... }:

{
  imports = [
    ./disko.nix
    "${modulesPath}/virtualisation/amazon-image.nix"
  ];

  fileSystems."/".autoResize = true;

  system.stateVersion = "25.05";
}
