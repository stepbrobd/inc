{
  imports = [
    ./hardware.nix

    ./as10779.nix
  ];

  networking = {
    # head -c4 /dev/urandom | od -A none -t x4
    hostId = "a7d06f05";
    hostName = "timah"; # https://en.wikipedia.org/wiki/Bukit_Timah
    domain = "sd.ysun.co";
  };
}
