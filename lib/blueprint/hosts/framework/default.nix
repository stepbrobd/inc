{ newHost, ... }:

newHost {
  name = "Framework";
  hostName = "framework";
  platform = "x86_64-linux";
  os = "nixos";
  provider = "owned";
  providerName = "Framework";
  type = "laptop";
  tags = [ "graphical" "niri" "noctalia" "nixbuild" "nix-community" ];
}
