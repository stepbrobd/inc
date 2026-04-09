{
  imports = [
    ./hardware.nix

    ./as10779.nix
  ];

  networking = {
    # head -c4 /dev/urandom | od -A none -t x4
    hostId = "cbe50cb2";
    hostName = "cradle"; # https://en.wikipedia.org/wiki/Cradle_Mountain
    domain = "sd.ysun.co";
  };
}
