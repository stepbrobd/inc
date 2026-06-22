{ lib, ... }:

{ config, pkgs, ... }:

let
  inherit (lib)
    mkIf mkMerge mkEnableOption mkPackageOption mkDefault mkOption types
    optional optionalAttrs;

  cfg = config.services.swetrix;
  hasTag = lib.hasTag config.networking.hostName;
  inherit (lib.blueprint.services.swetrix) domain;

  managedEnv =
    optionalAttrs cfg.clickhouse.enable
      {
        CLICKHOUSE_HOST = "http://[::1]";
        CLICKHOUSE_PORT = "8123";
        CLICKHOUSE_USER = "swetrix";
        CLICKHOUSE_PASSWORD = "";
        CLICKHOUSE_DATABASE = "analytics";
      }
    // optionalAttrs cfg.redis.enable {
      REDIS_HOST = "127.0.0.1";
      REDIS_PORT = "6379";
    }
    // optionalAttrs cfg.caddy.enable {
      BASE_URL = "https://${domain}";
      API_ORIGIN = "http://[::1]:5005";
      LISTEN_HOST = "::1";
      HOST = "::1";
      PORT = "3000";

      # see caddy config below
      CLIENT_IP_HEADER = "x-real-ip";

      # kanidm sso only
      OIDC_ENABLED = "true";
      OIDC_ONLY_AUTH = "true";
      OIDC_CLIENT_ID = "swetrix";
      OIDC_DISCOVERY_URL = "https://${lib.blueprint.services.kanidm.domain}/oauth2/openid/swetrix/.well-known/openid-configuration";
    };

  mkUnit =
    { description
    , exec
    , environment ? managedEnv // cfg.settings
    , after ? [ ]
    , wants ? [ ]
    , requires ? [ ]
    , extraServiceConfig ? { }
    }: {
      inherit description environment wants requires;
      after = [ "network.target" ] ++ after;
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        User = "swetrix";
        Group = "swetrix";
        StateDirectory = "swetrix";
        ExecStart = exec;
        Restart = "on-failure";
        RestartSec = 5;
        NoNewPrivileges = true;
        ProtectSystem = "strict";
        ProtectHome = true;
        PrivateTmp = true;
        ProtectKernelTunables = true;
        ProtectControlGroups = true;
        RestrictSUIDSGID = true;
      } // extraServiceConfig;
    };
in
{
  options.services.swetrix = {
    enable = mkEnableOption "swetrix";

    package = mkPackageOption pkgs "swetrix" { };

    redis.enable = mkEnableOption "a bundled Redis server, wired to Swetrix on 127.0.0.1:6379 (ioredis can't parse a bare IPv6 host)";

    clickhouse.enable = mkEnableOption "a bundled ClickHouse server, wired to Swetrix on [::1]:8123";

    caddy.enable = mkEnableOption "Caddy reverse proxy (routes /backend/* to API and / to the frontend then bind both services to [::1])";

    settings = mkOption {
      type = types.attrsOf types.str;
      default = { };
      example = lib.literalExpression ''
        {
          BASE_URL = "https://analytics.example.com";
          API_ORIGIN = "http://[::1]:5005";
          # only needed when not using services.swetrix.clickhouse.enable / redis.enable:
          CLICKHOUSE_HOST = "http://[::1]";
          CLICKHOUSE_PORT = "8123";
          REDIS_HOST = "127.0.0.1";
          REDIS_PORT = "6379";
        }
      '';
      description = ''
        Free-form environment passed verbatim to both Swetrix systemd services
        (frontend and API); every key/value pair becomes an environment variable.
        See <https://docs.swetrix.com/selfhosting/configuring> for the full list.

        When {option}`services.swetrix.clickhouse.enable` or
        {option}`services.swetrix.redis.enable` is set, the matching `CLICKHOUSE_*`
        / `REDIS_*` connection variables are filled in automatically; values given
        here take precedence.

        Values land world-readable in the Nix store, so inject secrets such as
        {env}`SECRET_KEY_BASE`, {env}`CLICKHOUSE_PASSWORD` and {env}`REDIS_PASSWORD`
        out of band instead, e.g. via
        {option}`systemd.services.swetrix-api.serviceConfig.EnvironmentFile`.
      '';
    };
  };

  config = mkMerge [
    (mkIf (hasTag "swetrix") {
      services.swetrix.enable = mkDefault true;
      services.swetrix.clickhouse.enable = mkDefault true;
      services.swetrix.redis.enable = mkDefault true;
      services.swetrix.caddy.enable = mkDefault true;

      sops.secrets."swetrix/environment" = { };
      systemd.services.swetrix-api.serviceConfig.EnvironmentFile = [ config.sops.secrets."swetrix/environment".path ];
    })

    (mkIf cfg.enable {
      users.groups.swetrix = { };
      users.users.swetrix = {
        isSystemUser = true;
        group = "swetrix";
        home = "/var/lib/swetrix";
        description = "Swetrix service user";
      };

      services.clickhouse = mkIf cfg.clickhouse.enable {
        enable = true;

        usersConfig.users.swetrix = {
          password = "";
          networks.ip = [ "127.0.0.1" "::1" ];
          profile = "default";
          quota = "default";
        };

        extraServerConfig = ''
          <clickhouse>
            <listen_host>::1</listen_host>
            <listen_host>127.0.0.1</listen_host>
            <logger><level>warning</level></logger>
            <query_thread_log remove="remove"/>
            <query_log remove="remove"/>
            <text_log remove="remove"/>
            <trace_log remove="remove"/>
            <metric_log remove="remove"/>
            <asynchronous_metric_log remove="remove"/>
            <session_log remove="remove"/>
            <part_log remove="remove"/>
          </clickhouse>
        '';

        extraUsersConfig = ''
          <clickhouse>
            <profiles><default>
              <log_queries>0</log_queries>
              <log_query_threads>0</log_query_threads>
            </default></profiles>
          </clickhouse>
        '';
      };

      services.redis.servers.swetrix = mkIf cfg.redis.enable {
        enable = true;
        bind = "127.0.0.1";
        port = 6379;
      };

      systemd.services.swetrix-api = mkUnit {
        description = "Swetrix analytics API";
        exec = "${pkgs.swetrix-api}/bin/swetrix-api";
        after = optional cfg.clickhouse.enable "clickhouse.service" ++ optional cfg.redis.enable "redis-swetrix.service";
        requires = optional cfg.clickhouse.enable "clickhouse.service" ++ optional cfg.redis.enable "redis-swetrix.service";
        extraServiceConfig.ExecStartPre = "${pkgs.swetrix-api}/bin/swetrix-api-clickhouse-init";
      };

      systemd.services.swetrix = mkUnit {
        description = "Swetrix analytics frontend";
        exec = "${cfg.package}/bin/swetrix";
        after = [ "swetrix-api.service" ];
        wants = [ "swetrix-api.service" ];
      };

      # backend -> ${domain}/backend 
      # o.w.    -> frontend
      services.caddy = mkIf cfg.caddy.enable {
        enable = true;
        virtualHosts.${domain}.extraConfig = ''
          import common
          handle_path /backend/* {
            reverse_proxy [::1]:5005 {
              header_up X-Real-IP {client_ip}
            }
          }
          handle {
            reverse_proxy [::1]:3000 {
              header_up X-Real-IP {client_ip}
            }
          }
        '';
      };
    })
  ];
}
