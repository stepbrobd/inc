{
  imports = [
    ./hardware.nix

    ./routing.nix
  ];

  networking = {
    # head -c4 /dev/urandom | od -A none -t x4
    hostId = "f068ae2b";
    hostName = "toompea"; # https://en.wikipedia.org/wiki/Toompea
    domain = "sd.ysun.co";
  };
}
