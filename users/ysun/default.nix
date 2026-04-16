{ lib, pkgs, ... }:

{
  programs.zsh.enable = true;

  users.users.ysun = {
    shell = pkgs.zsh;

    description = "Yifei Sun";
    home =
      if pkgs.stdenv.isLinux then
        lib.mkDefault "/home/ysun"
      else if pkgs.stdenv.isDarwin then
        lib.mkDefault "/Users/ysun"
      else
        abort "Unsupported OS";

    openssh.authorizedKeys = { inherit (lib.blueprint.users.ysun.openssh.authorizedKeys) keys; };
  } // lib.optionalAttrs pkgs.stdenv.isLinux {
    isNormalUser = true;
    extraGroups = [
      "audio"
      "docker"
      "input"
      "librepods"
      "networkmanager"
      "podman"
      "video"
      "wheel"
    ];
    hashedPassword = "$y$j9T$.4YGom.yj/t0BqlWv3ysg.$f.LzZrxQpB.vpmKd7mu4yxYWiERgEtTAxJHIGti2vg2";
  };
}
