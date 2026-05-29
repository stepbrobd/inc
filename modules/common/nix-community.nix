{ lib, ... }:

{ config, ... }:

let
  inherit (lib) mkDefault mkIf mkMerge mkEnableOption;

  hasTag = lib.hasTag config.networking.hostName;

  cfg = config.nix.nix-community;
in
{
  options.nix.nix-community.enable = mkEnableOption "nix-community builder";

  config = (mkMerge [
    (lib.mkIf (hasTag "nix-community") {
      nix.nixbuild.enable = mkDefault true;
    })

    (mkIf
      (cfg.enable # massive hack, use hm user age key to decrypt system keys
        && hasTag "laptop"
        && config ? home-manager
        && config.home-manager.users ? ysun
        && config.home-manager.users.ysun ? sops)
      {
        sops.age.keyFile = config.home-manager.users.ysun.sops.age.keyFile;
      })

    (mkIf cfg.enable {
      sops.secrets."nix-community/prv" = { };

      programs.ssh.extraConfig = ''
        Host aarch64-build-box.nix-community.org
          PubkeyAcceptedKeyTypes ssh-ed25519
          ServerAliveInterval 60
          IPQoS throughput
          IdentityFile ${config.sops.secrets."nix-community/prv".path}
      '';

      programs.ssh.knownHosts.nix-community = {
        hostNames = [ "aarch64-build-box.nix-community.org" ];
        publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG9uyfhyli+BRtk64y+niqtb+sKquRGGZ87f4YRc8EE1";
      };

      nix = {
        distributedBuilds = true;
        buildMachines = [{
          system = "aarch64-linux";
          hostName = "aarch64-build-box.nix-community.org";
          maxJobs = 100;
          supportedFeatures = [
            "benchmark"
            "big-parallel"
            "kvm"
            "nixos-test"
            "uid-range"
          ];
        }];
      };
    })
  ]);
}
