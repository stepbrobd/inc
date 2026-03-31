{ lib, ... }:

{
  home.file.".ssh/known_hosts_ca".text = "@cert-authority * ${lib.blueprint.ssh.ca}";

  programs.ssh = {
    enable = true;

    enableDefaultConfig = false;
    matchBlocks."*" = {
      forwardAgent = lib.mkDefault false;
      addKeysToAgent = lib.mkDefault "no";
      compression = lib.mkDefault false;
      serverAliveInterval = 60;
      hashKnownHosts = lib.mkDefault false;
      userKnownHostsFile = lib.concatStringsSep " " [
        "~/.ssh/known_hosts"
        "~/.ssh/known_hosts_ca"
      ];
    };

    extraConfig = "\n" + ''
      Host g5k
        WarnWeakCrypto no
        User yisun
        Hostname access.grid5000.fr

      Host *.g5k
        WarnWeakCrypto no
        User yisun
        ProxyCommand sh -c 'ssh g5k -W "$(basename %h .g5k):%p"'
    ''
      /* + "\n" +
      (if pkgs.stdenv.isLinux then ''
      Host *
          IdentityAgent "~/.1password/agent.sock"
      '' else if pkgs.stdenv.isDarwin then ''
      Host *
        IdentityAgent "~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
      '' else abort "Unsupported OS") */;
  };
}
