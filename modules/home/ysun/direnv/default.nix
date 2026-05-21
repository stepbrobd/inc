{ inputs, ... }:

{
  imports = [ inputs.direnv-instant.homeModules.direnv-instant ];

  programs.direnv-instant.enable = true;

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
    silent = true;
  };
}
