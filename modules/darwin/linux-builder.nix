{ pkgs, ... }:

{
  nix.linux-builder = {
    enable = true;
    ephemeral = true;
    maxJobs = 8;

    package = pkgs.darwin.linux-builder-x86_64;
    systems = [ "x86_64-linux" ];
    config = {
      virtualisation = {
        darwin-builder = {
          diskSize = 25 * 1024;
          memorySize = 8 * 1024;
        };
        cores = 8;
      };
    };
  };
}
