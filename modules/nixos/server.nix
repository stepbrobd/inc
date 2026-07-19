{ config, pkgs, ... }:

{
  i18n.defaultLocale = "en_US.UTF-8";
  time.timeZone = "Etc/UTC";

  networking.tempAddresses = "disabled";

  environment.systemPackages = with pkgs; [
    cacert
    file
    vim

    cfspeedtest
    coreutils
    dnsutils
    howfastly
    inetutils
    mtr
    tcpdump

    curl
    wget
  ];

  zramSwap.enable = true;

  programs.zsh.enableCompletion = pkgs.lib.mkForce false;
  programs.bash.completion.enable = pkgs.lib.mkForce false;

  services.journald.extraConfig = ''
    SystemMaxUse=64M
  '';
  services.logrotate.settings =
    let
      inherit (pkgs.lib) mkDefault mapAttrs;
    in
    {
      "/var/log/btmp" = mapAttrs (_: mkDefault) {
        frequency = "monthly";
        rotate = 1;
        create = "0660 root ${config.users.groups.utmp.name}";
        minsize = "1M";
      };
      "/var/log/wtmp" = mapAttrs (_: mkDefault) {
        frequency = "monthly";
        rotate = 1;
        create = "0664 root ${config.users.groups.utmp.name}";
        minsize = "1M";
      };
    };
}
