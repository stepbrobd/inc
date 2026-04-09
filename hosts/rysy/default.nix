{
  imports = [
    ./hardware.nix

    ./as10779.nix
  ];

  networking = {
    # head -c4 /dev/urandom | od -A none -t x4
    hostId = "fc15b7e8";
    hostName = "rysy"; # https://en.wikipedia.org/wiki/Rysy
    domain = "sd.ysun.co";
  };
}
