{
  imports = [
    ./hardware.nix

    ./routing.nix
  ];

  networking = {
    # head -c4 /dev/urandom | od -A none -t x4
    hostId = "243169a2";
    hostName = "namsan"; # https://en.wikipedia.org/wiki/Namsan_(Seoul)
    domain = "sd.ysun.co";
  };
}
