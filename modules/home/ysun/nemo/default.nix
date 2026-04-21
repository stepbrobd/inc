{ lib, ... }:

{ pkgs, ... }:

{
  xdg.desktopEntries.nemo = {
    name = "Nemo";
    exec = lib.getExe pkgs.nemo;
  };

  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "inode/directory" = [ "nemo.desktop" ];
      "application/x-gnome-saved-search" = [ "nemo.desktop" ];
    };
  };
}
