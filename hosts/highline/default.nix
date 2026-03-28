{
  imports = [
    ./hardware.nix

    ./as10779.nix
  ];

  networking = {
    # head -c4 /dev/urandom | od -A none -t x4
    hostId = "a9df2efe";
    hostName = "highline"; # https://en.wikipedia.org/wiki/High_Line
    domain = "sd.ysun.co";
  };
}
