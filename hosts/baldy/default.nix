{
  imports = [
    ./hardware.nix
  ];

  networking = {
    # head -c4 /dev/urandom | od -A none -t x4
    hostId = "a8bf807d";
    hostName = "baldy"; # https://en.wikipedia.org/wiki/Mount_San_Antonio
    domain = "sd.ysun.co";
  };
}
