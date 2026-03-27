{
  imports = [
    ./hardware.nix

    ./as10779.nix
  ];

  networking = {
    # head -c4 /dev/urandom | od -A none -t x4
    hostId = "a4c7c5aa";
    hostName = "halti";
    domain = "sd.ysun.co";
  };
}
