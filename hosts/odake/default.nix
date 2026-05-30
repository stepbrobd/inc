{
  imports = [
    ./hardware.nix

    ./as10779.nix
  ];

  networking = {
    # head -c4 /dev/urandom | od -A none -t x4
    hostId = "cbef444f";
    hostName = "odake"; # https://en.wikipedia.org/wiki/Mount_Odake_(Tokyo)
    domain = "sd.ysun.co";
  };
}
