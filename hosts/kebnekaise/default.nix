{
  imports = [
    ./hardware.nix

    ./as10779.nix
  ];

  networking = {
    # head -c4 /dev/urandom | od -A none -t x4
    hostId = "7419e258";
    hostName = "kebnekaise"; # https://en.wikipedia.org/wiki/Kebnekaise
    domain = "sd.ysun.co";
  };
}
