{
  imports = [
    ./hardware.nix
  ];

  networking = {
    # head -c4 /dev/urandom | od -A none -t x4
    hostId = "f8d9d310";
    hostName = "noches"; # https://the-detective-is-already-dead.fandom.com/wiki/Noches
    domain = "sd.ysun.co";
  };
}
