{ lib, inputs, ... }:

{
  imports = with inputs.self.homeManagerModules.ysun; [ minimal ];

  # desktop theming has no consumers on servers
  # keep stylix to CLI targets
  # like tmux, nushell, starship, etc.
  home.pointerCursor.enable = lib.mkForce false;
  stylix.icons.enable = lib.mkForce false;

  stylix.targets = {
    font-packages.enable = lib.mkForce false;
    fontconfig.enable = lib.mkForce false;
    gtk.enable = lib.mkForce false;
    qt.enable = lib.mkForce false;
    xresources.enable = lib.mkForce false;
  };
}
