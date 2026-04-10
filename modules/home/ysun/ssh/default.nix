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
      Host *
        ForwardAgent no
        ServerAliveInterval 60
        Compression no
        AddKeysToAgent no
        HashKnownHosts no
        UserKnownHostsFile ~/.ssh/known_hosts ~/.ssh/known_hosts_ca

      Host g5k
        WarnWeakCrypto no
        User yisun
        Hostname access.grid5000.fr

      Host *.*.g5k
        WarnWeakCrypto no
        ProxyCommand sh -c 'h=%h; node="''${h%%%%.*}"; site="''${h#*.}"; site="''${site%%.g5k}"; ssh "''${site}.g5k" -W "''${node}:%p"'

      Host *.g5k
        WarnWeakCrypto no
        User yisun
        ProxyCommand sh -c 'ssh g5k -W "$(basename %h .g5k):%p"'
    '';
  };
}
