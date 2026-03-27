{ lib, ... }:

{ config, ... }:

let
  cfg = config.services.jitsi;
in
{
  options.services.jitsi = {
    enable = lib.mkEnableOption "Jitsi Meet";

    domain = lib.mkOption {
      default = "meet.ysun.co";
      description = "Main domain to serve Jitsi Meet on";
      example = "meet.ysun.co";
      type = lib.types.str;
    };
  };

  config = lib.mkIf cfg.enable {
    nixpkgs.config.permittedInsecurePackages = [
      "jitsi-meet-1.0.8792"
    ];

    services.caddy.virtualHosts.${cfg.domain} = {
      extraConfig = lib.mkBefore ''
        import common
      '';
    };

    services.prosody.checkConfig = false;
    services.jitsi-videobridge.openFirewall = true;

    services.jitsi-meet = {
      enable = true;
      hostName = cfg.domain;

      caddy.enable = true;
      nginx.enable = false;

      prosody.lockdown = true;

      config = {
        defaultLang = "en";
        analytics.disabled = true;
        enableWelcomePage = false;
        prejoinPageEnabled = true;
        requireDisplayName = true;
        maxFullResolutionParticipants = 1;
        stunServers = [
          { urls = "turn:turn.matrix.org:3478?transport=udp"; }
          { urls = "turn:turn.matrix.org:3478?transport=tcp"; }
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
  };
}
