{
  imports = [
    ./hardware.nix

    ./as10779.nix
  ];

  networking = {
    # head -c4 /dev/urandom | od -A none -t x4
    hostId = "efb7966a";
    hostName = "morasko"; # https://en.wikipedia.org/wiki/Morasko
    domain = "sd.ysun.co";
  };
}
