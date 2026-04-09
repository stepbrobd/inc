{
  imports = [
    ./hardware.nix

    ./as10779.nix
  ];

  networking = {
    # head -c4 /dev/urandom | od -A none -t x4
    hostId = "71fad1e8";
    hostName = "lantau"; # https://en.wikipedia.org/wiki/Lantau_Peak
    domain = "sd.ysun.co";
  };
}
