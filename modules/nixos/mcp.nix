{ lib, ... }:

{ config, pkgs, ... }:

let
  hasTag = lib.hasTag config.networking.hostName;
  cfg = config.services.mcp;
  bp = lib.blueprint;
  issuer = "https://${bp.services.kanidm.domain}/oauth2/openid/${cfg.clientId}";
  resource = "https://${cfg.domain}/mcp";
  socketDir = lib.dirOf cfg.socket;
in
{
  options.services.mcp = {
    domain = lib.mkOption {
      type = lib.types.str;
      default = bp.services.mcp.domain;
      description = "Publicly reachable hostname";
    };
    user = lib.mkOption {
      type = lib.types.str;
      default = "ysun";
      description = "Run as this user";
    };
    clientId = lib.mkOption {
      type = lib.types.str;
      default = "mcp";
      description = "OAuth2 Client ID";
    };
    scope = lib.mkOption {
      type = lib.types.str;
      default = "mcp:shell";
      description = "Token scope";
    };
    shell = lib.mkOption {
      type = lib.types.package;
      default = pkgs.bashInteractive;
      description = "Runner shell";
    };
    packages = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [ ];
      description = "Packages made available in PATH";
    };
    defaultTimeout = lib.mkOption {
      type = lib.types.ints.positive;
      default = 60;
    };
    maxTimeout = lib.mkOption {
      type = lib.types.ints.positive;
      default = 200;
    };
    maxOutputBytes = lib.mkOption {
      type = lib.types.ints.positive;
      default = 100000;
    };
    socket = lib.mkOption {
      type = lib.types.str;
      default = "/run/mcp/mcp.sock";
      description = "Unix socket";
    };
    environment = lib.mkOption {
      type = lib.types.submodule { freeformType = lib.types.attrsOf lib.types.str; };
      default = { };
      description = "Environment variables as KV pairs";
    };
  };

  config = lib.mkIf (hasTag "mcp") {
    services.caddy.enable = true;
    # request bodies are shell commands (which ngwaf would detect as attacks)
    services.sigsci-agent.enable = lib.mkForce false;

    services.mcp.environment = lib.mapAttrs (_: lib.mkDefault) {
      MCP_ISSUER = issuer;
      MCP_AUDIENCE = cfg.clientId;
      MCP_RESOURCE = resource;
      MCP_RESOURCE_METADATA_URL = "https://${cfg.domain}/.well-known/oauth-protected-resource/mcp";
      MCP_REQUIRED_SCOPE = cfg.scope;
      MCP_SHELL = lib.getExe cfg.shell;
      MCP_DEFAULT_TIMEOUT_SECS = toString cfg.defaultTimeout;
      MCP_MAX_TIMEOUT_SECS = toString cfg.maxTimeout;
      MCP_MAX_OUTPUT_BYTES = toString cfg.maxOutputBytes;
      MCP_AUDIT_LOG = "%S/mcp/audit.log";
      SSH_AUTH_SOCK = "%t/gnupg/S.gpg-agent.ssh";
      PATH = "/etc/profiles/per-user/${cfg.user}/bin:/run/current-system/sw/bin";
    };

    services.caddy.virtualHosts.${cfg.domain}.extraConfig = ''
      import base
      reverse_proxy unix/${cfg.socket} {
        header_up X-Real-IP {client_ip}
        flush_interval -1
      }
    '';

    # the user manager owns the socket
    # caddy connects through the caddy group
    systemd.tmpfiles.rules = [ "d ${socketDir} 0750 ${cfg.user} caddy -" ];

    users.users.${cfg.user} = {
      linger = true;
      extraGroups = [ "caddy" ];
    };

    home-manager.users.${cfg.user} = {
      home.packages = cfg.packages;

      systemd.user.sockets.mcp = {
        Unit.Description = "MCP shell socket";
        Socket = {
          ListenStream = cfg.socket;
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
          Environment = lib.mapAttrsToList (n: v: "${n}=${v}") cfg.environment;
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
