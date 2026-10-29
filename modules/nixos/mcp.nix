{ lib, ... }:

{ config, pkgs, ... }:

let
  hasTag = lib.hasTag config.networking.hostName;
  cfg = config.services.mcp;
  bp = lib.blueprint;
  domain = bp.services.mcp.domain;
  socket = "/run/mcp/mcp.sock";
  socketDir = lib.dirOf socket;
  issuer = "https://${bp.services.kanidm.domain}/oauth2/openid/mcp";
  resource = "https://${domain}/mcp";
in
{
  options.services.mcp = {
    user = lib.mkOption {
      type = lib.types.str;
      default = "ysun";
      description = "User the tool will runs as (inheriting access and permissions)";
    };
    settings = lib.mkOption {
      type = lib.types.submodule { freeformType = lib.types.attrsOf lib.types.str; };
      default = { };
      description = "Service environment variables as KV pairs";
    };
  };

  config = lib.mkIf (hasTag "mcp") {
    services.mcp.settings = lib.mapAttrs (_: lib.mkDefault) {
      MCP_ISSUER = issuer;
      MCP_AUDIENCE = "mcp";
      MCP_RESOURCE = resource;
      MCP_RESOURCE_METADATA_URL = "https://${domain}/.well-known/oauth-protected-resource/mcp";
      MCP_REQUIRED_SCOPE = "mcp:shell";
      MCP_AUDIT_LOG = "%S/mcp/audit.log";
      SSH_AUTH_SOCK = "%t/gnupg/S.gpg-agent.ssh";
      PATH = "/etc/profiles/per-user/${cfg.user}/bin:/run/current-system/sw/bin";
    };

    services.caddy.enable = true;
    # request bodies are shell commands which the ngwaf would read as attacks
    services.sigsci-agent.enable = lib.mkForce false;

    services.caddy.virtualHosts.${domain}.extraConfig = ''
      import base
      import anthropic
      handle @anthropic {
        reverse_proxy unix/${socket} {
          header_up X-Real-IP {client_ip}
          flush_interval -1
        }
      }
      respond 404
    '';

    # ban hosts that present invalid tokens
    services.fail2ban = {
      enable = lib.mkDefault true;
      banaction = lib.mkDefault "nftables[type=custom,blocktype=drop]";
      banaction-allports = lib.mkDefault "nftables[type=custom,blocktype=drop]";
      jails.mcp.settings = {
        backend = "systemd";
        filter = "mcp";
        maxretry = 1;
      };
    };
    environment.etc."fail2ban/filter.d/mcp.conf".text = ''
      [Definition]
      failregex = auth denied from <HOST> reason=invalid_token
      journalmatch = _SYSTEMD_USER_UNIT=mcp.service
    '';

    # the user manager owns the socket and caddy connects through the caddy group
    systemd.tmpfiles.rules = [ "d ${socketDir} 0750 ${cfg.user} caddy -" ];

    users.users.${cfg.user} = {
      linger = true;
      extraGroups = [ "caddy" ];
    };

    home-manager.users.${cfg.user} = {
      systemd.user.sockets.mcp = {
        Unit.Description = "MCP shell socket";
        Socket = {
          ListenStream = socket;
          SocketMode = "0660";
          SocketGroup = "caddy";
        };
        Install.WantedBy = [ "sockets.target" ];
      };

      systemd.user.services.mcp = {
        Unit = {
          Description = "Authenticated MCP shell";
          Requires = [ "mcp.socket" ];
          After = [ "mcp.socket" ];
        };
        Service = {
          ExecStart = lib.getExe pkgs.mcp;
          Environment = lib.mapAttrsToList (n: v: "${n}=${v}") cfg.settings;
          Restart = "on-failure";
          RestartSec = 5;
          StateDirectory = "mcp";
          NoNewPrivileges = true;
          RestrictSUIDSGID = true;
          LockPersonality = true;
          RestrictRealtime = true;
          ProtectClock = true;
        };
        Install.WantedBy = [ "default.target" ];
      };
    };
  };
}
