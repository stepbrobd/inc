{
  imports = [
    ./hardware.nix
  ];

  networking = {
    # head -c4 /dev/urandom | od -A none -t x4
    hostId = "3839a572";
    hostName = "roraima"; # https://en.wikipedia.org/wiki/Mount_Roraima
    domain = "sd.ysun.co";
  };
}
