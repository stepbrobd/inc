{
  imports = [
    ./hardware.nix

    ./as10779.nix
  ];

  networking = {
    # head -c4 /dev/urandom | od -A none -t x4
    hostId = "49f52dfd";
    hostName = "montmartre"; # https://en.wikipedia.org/wiki/Montmartre
    domain = "sd.ysun.co";
  };
}
