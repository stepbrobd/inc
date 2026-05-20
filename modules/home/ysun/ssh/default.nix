{ lib, ... }:

{
  home.file.".ssh/known_hosts_ca".text = "@cert-authority * ${lib.blueprint.ssh.ca}";

  programs.ssh = {
    enable = true;

    enableDefaultConfig = false;
    settings = {
      "g5k" = {
        WarnWeakCrypto = "no";
        User = "yisun";
        Hostname = "access.grid5000.fr";
      };

      "*.*.g5k" = lib.hm.dag.entryAfter [ "g5k" ] {
        WarnWeakCrypto = "no";
        ProxyCommand = ''
          sh -c 'h=%h; node="''${h%%%%.*}"; site="''${h#*.}"; site="''${site%%.g5k}"; ssh "''${site}.g5k" -W "''${node}:%p"'
        '';
      };

      "*.g5k" = lib.hm.dag.entryAfter [ "*.*.g5k" ] {
        WarnWeakCrypto = "no";
        User = "yisun";
        ProxyCommand = ''
          sh -c 'ssh g5k -W "$(basename %h .g5k):%p"'
        '';
      };

      "*" = {
        ForwardAgent = lib.mkDefault false;
        AddKeysToAgent = lib.mkDefault "no";
        Compression = lib.mkDefault false;
        ServerAliveInterval = 60;
        HashKnownHosts = lib.mkDefault false;
        UserKnownHostsFile = [
          "~/.ssh/known_hosts"
          "~/.ssh/known_hosts_ca"
        ];
      };
    };
  };
}
