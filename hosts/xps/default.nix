{ config, pkgs, ... }:

{
  imports = [ ./hardware.nix ];

  # massive hack, use hm user age key to decrypt system keys
  sops.age.keyFile = config.home-manager.users.ysun.sops.age.keyFile;

  time.timeZone = "Europe/Paris";

  services.openssh.enable = true;

  # osu!
  hardware.opentabletdriver.enable = true;

  networking = {
    # head -c4 /dev/urandom | od -A none -t x4
    hostId = "a39d07b7";
    hostName = "xps";
    domain = "sd.ysun.co";
    networkmanager.enable = true;
  };

  environment.systemPackages = with pkgs; [
    cacert
    sbctl

    coreutils
    inetutils
    dnsutils
    pciutils
    binutils

    direnv
    nix-direnv
    vim
    git
    curl
    wget
  ];

  users.mutableUsers = false;
}
