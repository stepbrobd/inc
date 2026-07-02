{ lib, ... }:

{ config, pkgs, ... }:

let
  hasTag = lib.hasTag config.networking.hostName;
in
{
  config = lib.mkIf (hasTag "ci") {
    users.groups.ci = { };
    users.users.ci = {
      description = "CI";
      home = "/var/lib/ci";
      createHome = true;
      isSystemUser = true;

      shell = pkgs.bash;

      group = "ci";
      extraGroups = [ "wheel" ];

      # restrict -> no pty/forwarding command execution only for colmena
      openssh.authorizedKeys.keys = [ "restrict ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGRLXe5W3Xg30YU3C7w1POjVE7CPLYabnxLsvgl2Rtp9" ];
    };

    # ci key should only works from inside tailnet
    services.openssh.settings.DenyUsers = [ "ci@!100.64.0.0/10,!fd7a:115c:a1e0::/48,*" ];
  };
}
