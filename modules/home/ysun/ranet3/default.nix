{ pkgs, ... }:

{
  home.packages = [ pkgs.ranet3 ];

  xdg.configFile."carapace/choices/ranet3".text = "ranet3/cobra@bridge\n";
}
