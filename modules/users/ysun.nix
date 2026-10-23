{ lib, ... }:

{ config, pkgs, ... }:

{
  programs.zsh.enable = true;

  users.users.ysun = {
    shell = pkgs.nushell;

    description = "Yifei Sun";
    home =
      if pkgs.stdenv.hostPlatform.isLinux then
        lib.mkDefault "/home/ysun"
      else if pkgs.stdenv.hostPlatform.isDarwin then
        lib.mkDefault "/Users/ysun"
      else
        abort "Unsupported OS";

    openssh.authorizedKeys = { inherit (lib.blueprint.users.ysun.openssh.authorizedKeys) keys; };
  } // lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
    isNormalUser = true;

    hashedPassword = "$y$j9T$.4YGom.yj/t0BqlWv3ysg.$f.LzZrxQpB.vpmKd7mu4yxYWiERgEtTAxJHIGti2vg2";

    extraGroups = lib.attrNames (lib.filterAttrs (_: enabled: enabled) {
      wheel = true;

      audio = config.services.pipewire.enable;
      librepods = config.programs.librepods.enable;

      i2c = config.hardware.i2c.enable;
      input = config.hardware.uinput.enable;
      tss = config.security.tpm2.enable;
      uinput = config.hardware.uinput.enable;
      video = config.hardware.graphics.enable;

      bird = config.services.bird.enable;
      networkmanager = config.networking.networkmanager.enable;

      docker = config.virtualisation.docker.enable;
      podman = config.virtualisation.podman.enable;
    });
  };
}
