{ lib, ... }:

{ config, pkgs, ... }:

let
  inherit (lib) forEach mkDefault mkIf mkMerge mkEnableOption mkOption types;

  hasTag = lib.hasTag config.networking.hostName;

  cfg = config.nix.nixbuild;
in
{
  options.nix.nixbuild = {
    enable = mkEnableOption "nixbuild builder";

    systems = mkOption {
      type = with types; listOf str;
      default = [ "aarch64-linux" ];
      example = [ "x86_64-linux" "aarch64-linux" ];
      description = "https://docs.nixbuild.net/getting-started/index.html#quick-nixos-configuration";
    };
  };

  config = (mkMerge [
    (lib.mkIf (hasTag "nixbuild") {
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
      sops.secrets."nixbuild/prv" = { };

      programs.ssh.extraConfig = ''
        Host eu.nixbuild.net
          WarnWeakCrypto no
          PubkeyAcceptedKeyTypes ssh-ed25519
          ServerAliveInterval 60
          IPQoS throughput
          IdentityFile ${config.sops.secrets."nixbuild/prv".path}
      '';

      # doing it this way because we might need shell access for settings
      programs.ssh.knownHosts.nixbuild = {
        hostNames = [ "eu.nixbuild.net" ];
        publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPIQCZc54poJ8vqawd8TraNryQeJnvH1eLpIDgbiqymM";
      };

      nix = {
        distributedBuilds = true;
        buildMachines = forEach cfg.systems (system: {
          inherit system;
          hostName = "eu.nixbuild.net";
          maxJobs = 100;
          supportedFeatures = [ "big-parallel" "benchmark" "kvm" "nixos-test" ];
        });

        # should only be available if have nix build ssh key
        settings.extra-substituters = [ "ssh-ng://eu.nixbuild.net" ];
        settings.trusted-public-keys = [ "nixbuild.net/CQ9XPX-1:8WFF5qINzG2FrrvIePqdH+XraKME30g3+Es3aCWBw24=" ];
      };

      environment.systemPackages = [
        (pkgs.writeShellApplication {
          name = "nixbuild";
          runtimeInputs = with pkgs; [ rlwrap ];
          text = "sudo rlwrap ssh eu.nixbuild.net shell";
        })
      ];
    })
  ]);
}
