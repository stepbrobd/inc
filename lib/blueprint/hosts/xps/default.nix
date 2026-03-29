{ newHost, ... }:

newHost {
  name = "XPS";
  hostName = "xps";
  platform = "x86_64-linux";
  os = "nixos";
  provider = "owned";
  providerName = "Dell";
  type = "laptop";
  tags = [ "graphical" "hyprland" "noctalia" ];
}
