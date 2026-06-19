{ pkgs, ... }:

{
  home.packages = [ pkgs.nixvim ];
  home.sessionVariables.EDITOR = "nvim";
}
