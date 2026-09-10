{ lib, ... }:

{ config, pkgs, ... }:

let
  cfg = config.services.jitsi;
  hasTag = lib.hasTag config.networking.hostName;
  inherit (lib.blueprint.services.jitsi) domain;
in
{
  options.services.jitsi = {
    enable = lib.mkEnableOption "Jitsi Meet";
  };

  config = lib.mkMerge [
    (lib.mkIf (hasTag "jitsi") {
      services.jitsi.enable = lib.mkDefault true;
    })
    (lib.mkIf cfg.enable {
      services.caddy.virtualHosts.${domain} = {
        extraConfig = lib.mkBefore ''
          import common

          handle_path /_oidc/* {
            reverse_proxy [::1]:3000
          }
        '';
      };

      sops.secrets."jitsi/jwt".owner = "prosody";
      sops.secrets."jitsi/oidc" = { };

      # FileLine() below reads sops path that doesnt exist in build sandbox
      services.prosody.checkConfig = false;
      # keep cjson from the module default
      # token auth additionally needs basexx luaossl inspect
      services.prosody.package = pkgs.prosody.override {
        withExtraLuaPackages = p: with p;[
          basexx
          cjson
          inspect
          luaossl
        ];
      };
      services.prosody.virtualHosts.${domain}.extraConfig = ''
        app_id = "jitsi"
        app_secret = FileLine("${config.sops.secrets."jitsi/jwt".path}")
        enable_domain_verification = false
      '';
      # nixpkgs still lists a few global modules that jitsi-meet dropped in jitsi/jitsi-meet#17453
      services.prosody.extraModules = lib.mkForce [
        "conference_duration"
        "external_services"
        "limits_exception"
        "muc_breakout_rooms"
        "muc_domain_mapper"
        "muc_hide_all"
        "muc_lobby_rooms"
        "muc_meeting_id"
        "muc_rate_limit"
        "persistent_lobby"
        "smacks"
      ];

      # secureDomain sets type = "XMPP"
      # JWT keeps login-url = ${domain} as authenticated domain marker
      services.jicofo.config.jicofo.authentication.type = lib.mkForce "JWT";

      systemd.services.jitsi-openid = {
        wantedBy = [ "multi-user.target" ];
        after = [ "network-online.target" ];
        wants = [ "network-online.target" ];
        environment = {
          LISTEN_ADDR = "[::1]:3000";
          JITSI_URL = "https://${domain}";
          JITSI_SUB = domain;
          ISSUER_URL = "https://${lib.blueprint.services.kanidm.domain}/oauth2/openid/jitsi";
          BASE_URL = "https://${domain}/_oidc/";
          CLIENT_ID = "jitsi";
          SCOPES = "openid profile email";
          VERIFY_ACCESS_TOKEN_HASH = "false"; # kanidm doesnt include at_hash in code-flow id tokens
          JITSI_SECRET_FILE = "%d/jwt";
          CLIENT_SECRET_FILE = "%d/oidc";
        };
        serviceConfig = {
          ExecStart = lib.getExe pkgs.jitsi-openid;
          DynamicUser = true;
          LoadCredential = [
            "jwt:${config.sops.secrets."jitsi/jwt".path}"
            "oidc:${config.sops.secrets."jitsi/oidc".path}"
          ];
          Restart = "on-failure";
          RestartSec = 5;
        };
      };

      services.jitsi-videobridge.openFirewall = true;

      services.jitsi-meet = {
        enable = true;
        hostName = domain;

        caddy.enable = true;
        nginx.enable = false;
        prosody.lockdown = true;
        jibri.enable = true;

        secureDomain = {
          enable = true;
          authentication = "token";
        };

        config = {
          defaultLang = "en";
          analytics.disabled = true;
          enableWelcomePage = false;
          # streaming only
          fileRecordingsEnabled = false;
          localRecording = {
            disable = false;
            disableSelfRecording = false;
          };
          liveStreaming = {
            enabled = true;
            validatorRegExpString = "^rtmps?://.*|^(?:[a-zA-Z0-9]{4}(?:-(?!$)|$)){4}";
          };
          prejoinConfig.enabled = true;
          requireDisplayName = true;
          maxFullResolutionParticipants = 1;
          tokenAuthUrl = "https://${domain}/_oidc/room/{room}";
          tokenAuthUrlAutoRedirect = true;
          p2p.stunServers = [
            { urls = "stun:stun.cloudflare.com:3478"; }
            { urls = "stun:meet-jit-si-turnrelay.jitsi.net:443"; }
            { urls = "stun:stun.l.google.com:19302"; }
          ];
          constraints.video.height = {
            ideal = 720;
            max = 1080;
            min = 240;
          };
        };

        interfaceConfig = {
          DISABLE_PRESENCE_STATUS = true;
          GENERATE_ROOMNAMES_ON_WELCOME_PAGE = false;
          SHOW_JITSI_WATERMARK = false;
          SHOW_WATERMARK_FOR_GUESTS = false;
        };
      };
    })
  ];
}
