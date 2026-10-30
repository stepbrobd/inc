{ lib, ... }:

{ config, pkgs, ... }:

let
  hasTag = lib.hasTag config.networking.hostName;
  cfg = config.services.mcp;
  bp = lib.blueprint;
  domain = bp.services.mcp.domain;

  socket = "/run/mcp/mcp.sock";
  socketDir = lib.dirOf socket;

  resource = "https://${domain}/mcp";
  issuer = "https://${bp.services.kanidm.domain}/oauth2/openid/mcp";

  accessLog = "${config.services.caddy.logDir}/access-${domain}.log";
  # https://platform.claude.com/docs/en/api/ip-addresses, also the caddy anthropic snippet
  anthropic = "160.79.104.0/21";
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

    # caddy only lets anthropic through
    services.fail2ban = {
      enable = lib.mkDefault true;
      jails.mcp = {
        filter.Definition = {
          failregex = ''^\{.*"client_ip":"<ADDR>"'';
          datepattern = ''"ts":{EPOCH}'';
        };
        settings = {
          backend = "auto";
          logpath = accessLog;
          filter = "mcp";
          maxretry = 1;
          port = "443";
          protocol = "tcp,udp";
          banaction = "nftables[type=multiport,blocktype=drop]";
          ignoreip = lib.concatStringsSep " " (config.services.fail2ban.ignoreIP ++ [ anthropic ] ++ lib.concatMap (n: n.ipv4 ++ n.ipv6) (lib.attrValues bp.net));
        };
      };
    };

    systemd.tmpfiles.rules = [
      "d ${socketDir} 2750 ${cfg.user} caddy -"
      # fail2ban refuses to start when a jail's log does not exist yet
      "f ${accessLog} 0640 caddy caddy -"
    ];

    users.users.${cfg.user}.linger = true;

    home-manager.users.${cfg.user} = {
      systemd.user.sockets.mcp = {
        Unit.Description = "MCP shell socket";
        Socket = {
          ListenStream = socket;
          SocketMode = "0660";
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
        };
        Install.WantedBy = [ "default.target" ];
      };
    };
  };
}
