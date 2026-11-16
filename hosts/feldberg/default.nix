{
  imports = [
    ./hardware.nix

    ./routing.nix
  ];

  networking = {
    # head -c4 /dev/urandom | od -A none -t x4
    hostId = "7a349911";
    hostName = "feldberg"; # https://en.wikipedia.org/wiki/Großer_Feldberg
    domain = "sd.ysun.co";
  };
}
