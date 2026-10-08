{ lib, ... }:

{ pkgs
, osConfig ? { networking.hostName = ""; }
, ...
}:

let
  hasTag = lib.hasTag osConfig.networking.hostName;
in
{
  home.packages = lib.mkIf (!hasTag "ranet3") [ pkgs.ranet3 ];

  xdg.configFile."carapace/choices/ranet3".text = "ranet3/cobra@bridge\n";
}
