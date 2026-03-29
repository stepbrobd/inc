{ pkgs, ... }:

{
  imports = [ ./hardware.nix ];

  i18n.defaultLocale = "en_US.UTF-8";
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
    bitwarden-desktop

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

  # nix.nixbuild.enable = true;
}
