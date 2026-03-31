{ lib, ... }:

{
  system.activationScripts.extraActivation.text = ''
    if [[ "$(systemsetup -getremotelogin | sed 's/Remote Login: //')" == "Off" ]]; then
      launchctl load -w /System/Library/LaunchDaemons/ssh.plist
    fi
  '';

  services.openssh = {
    hostKeys = [{
      type = "ed25519";
      path = "/etc/ssh/ssh_host_ed25519_key";
    }];

    extraConfig = ''
      TrustedUserCAKeys               /etc/ssh/ca.pub
      ChallengeResponseAuthentication no
      KbdInteractiveAuthentication    no
      PasswordAuthentication          no
      PermitRootLogin                 no
      StrictModes                     yes
      UsePAM                          yes

      LoginGraceTime                  30
      MaxAuthTries                    5
      MaxStartups                     10:30:60
      PerSourceMaxStartups            1
      AllowAgentForwarding            no
    '';
  };

  environment.etc."ssh/ca.pub".text = lib.blueprint.ssh.ca;

  environment.etc."ssh/sshd_config".text = ''
    Include            /etc/ssh/sshd_config.d/*
    AuthorizedKeysFile .ssh/authorized_keys
  '' + (
    let
      # mostly pq but have fallback for legacy clients
      kex = lib.concatStringsSep "," [
        "mlkem768x25519-sha256"
        "sntrup761x25519-sha512"
        "sntrup761x25519-sha512@openssh.com"
        "curve25519-sha256" # fallback
      ];
      cipher = lib.concatStringsSep "," [
        "chacha20-poly1305@openssh.com"
        "aes256-ctr" # fallback
      ];
      mac = lib.concatStringsSep "," [
        "hmac-sha2-512-etm@openssh.com"
        "hmac-sha2-256-etm@openssh.com"
        "hmac-sha2-512" # fallback
      ];
    in
    ''
      KexAlgorithms ${kex}
      Ciphers       ${cipher}
      Macs          ${mac}
    ''
  );
}
