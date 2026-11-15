{
  imports = [
    ./hardware.nix

    ./as10779.nix
  ];

  networking = {
    # head -c4 /dev/urandom | od -A none -t x4
    hostId = "f776f859";
    hostName = "guadalupe"; # https://en.wikipedia.org/wiki/Guadalupe_Peak
    domain = "sd.ysun.co";
  };
}
