{ pkgs, ... }:

{
  fonts.packages = with pkgs; [
    font-awesome
    furifont
    nerd-fonts.intone-mono
    nerd-fonts.jetbrains-mono
    san-francisco
  ];
}
