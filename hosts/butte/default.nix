{
  imports = [
    ./hardware.nix

    ./as10779.nix
  ];

  networking = {
    # head -c4 /dev/urandom | od -A none -t x4
    hostId = "a1cc1c58";
    hostName = "butte"; # https://en.wikipedia.org/wiki/Parc_des_Buttes_Chaumont
    domain = "sd.ysun.co";
  };
}
