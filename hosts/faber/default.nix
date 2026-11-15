{
  imports = [
    ./hardware.nix

    ./as10779.nix
  ];

  networking = {
    # head -c4 /dev/urandom | od -A none -t x4
    hostId = "7bd6a88d";
    hostName = "faber"; # https://en.wikipedia.org/wiki/Mount_Faber
    domain = "sd.ysun.co";
  };
}
