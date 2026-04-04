{
  imports = [
    ./hardware.nix
  ];

  networking = {
    # head -c4 /dev/urandom | od -A none -t x4
    hostId = "a10a15e7";
    hostName = "oxide"; # https://oxide.computer
    domain = "sd.ysun.co";
  };
}
