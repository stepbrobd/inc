{ inputs, lib, ... }:

{ config, ... }:

{
  imports = with inputs; [
    garnix.nixosModules.garnix
    self.nixosModules.passwordless
  ];

  sops = {
    age = {
      keyFile = lib.mkForce "/var/garnix/keys/repo-key";
      sshKeyPaths = lib.mkForce [ ];
    };
    gnupg = {
      home = lib.mkForce null;
      sshKeyPaths = lib.mkForce [ ];
    };
  };

  # https://garnix.io/docs/hosting/branch
  boot.loader.grub.device = "/dev/sda";
  fileSystems."/" = {
    device = "/dev/sda1";
    fsType = "ext4";
  };

  garnix.server = {
    enable = true;
    persistence = {
      enable = true;
      name = config.networking.hostName;
    };
  };

  # try and see if i can use networkd
  # networking.useNetworkd = lib.mkForce false;
}
