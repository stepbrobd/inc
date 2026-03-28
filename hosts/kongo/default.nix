{
  imports = [
    ./hardware.nix

    ./as10779.nix
  ];

  networking = {
    # head -c4 /dev/urandom | od -A none -t x4
    hostId = "f222f0f0";
    hostName = "kongo"; # https://en.wikipedia.org/wiki/Mount_Kongō
    domain = "sd.ysun.co";
  };
}
