{
  imports = [
    ./hardware.nix

    ./as10779.nix
  ];

  networking = {
    # head -c4 /dev/urandom | od -A none -t x4
    hostId = "11889b3f";
    hostName = "watchung"; # https://en.wikipedia.org/wiki/Watchung_Mountains
    domain = "sd.ysun.co";
  };
}
