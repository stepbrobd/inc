{ config, lib, pkgs, ... }:

let
  inherit (lib.blueprint.services.hydra) domain;
in
{
  services.caddy = {
    enable = true;

    virtualHosts.${domain}.extraConfig = ''
      import common
      reverse_proxy ${toString config.services.hydra.listenHost}:${toString config.services.hydra.port}
    '';
  };

  sops.secrets.hydra = {
    owner = "hydra";
    group = "hydra";
    mode = "440";
  };

  services.hydra = {
    enable = true;
    logo = ./logo.png;

    useSubstitutes = true;
    minimumDiskFree = 5;
    minimumDiskFreeEvaluator = 5;

    hydraURL = "https://${domain}";
    listenHost = "127.0.0.1"; # starman/net::server cannot parse ipv6 in -h flag
    port = 10069;
    notificationSender = "hydra@localhost";

    extraConfig =
      # basic config
      ''
        tracker = <script defer data-domain="${domain}" src="https://${lib.blueprint.services.plausible.domain}/js/script.file-downloads.hash.outbound-links.js"></script>

        email_notification = 0

        <dynamicruncommand>
          enable = 1
        </dynamicruncommand>
      '' + # generic oidc
      ''
        enable_hydra_login = 0
        enable_oidc_login = 1
        oidc_client_id = "hydra"
        oidc_scope = "openid email profile groups"
        oidc_auth_uri = "https://sso.ysun.co/ui/oauth2"
        oidc_token_uri = "https://sso.ysun.co/oauth2/token"
        oidc_userinfo_uri = "https://sso.ysun.co/oauth2/openid/hydra/userinfo"
        include ${config.sops.secrets.hydra.path}

        <oidc_role_mapping>
          hydra.admins@ysun.co = admin
          hydra.admins@ysun.co = bump-to-front
          hydra.users@ysun.co = cancel-build
          hydra.users@ysun.co = eval-jobset
          hydra.users@ysun.co = create-projects
          hydra.users@ysun.co = restart-jobs
        </oidc_role_mapping>
      '';
  };

  nix = {
    settings.allowed-uris = [
      "flake:"
      "git+https:"
      "git+ssh:"
      "github:"
      "gitlab:"
      "https:"
      "path:"
      "sourcehut:"
    ];

    buildMachines = [
      {
        hostName = "localhost";
        system = config.nixpkgs.hostPlatform.system;
        supportedFeatures = [
          "kvm"
          "nixos-test"
          "big-parallel"
          "benchmark"
        ];
        maxJobs = 8;
      }
    ];

    extraOptions = ''
      build-timeout = 86400  # 24 hours
    '';
  };
}
