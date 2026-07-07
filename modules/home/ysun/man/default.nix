{ pkgs, ... }:

{
  home.sessionVariables.MANPAGER = "nvim +Man!";

  home.packages = with pkgs; [
    man-pages
    man-pages-posix
  ];
}
