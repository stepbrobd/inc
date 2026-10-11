{ lib, ... } @ args:

{ config, ... }:

let
  metricsTarget = "[::1]:9019";
  metricsPath = "/metrics";

  report = "https://${lib.blueprint.services.go-csp-collector.domain}";
  site = [ "'self'" "https://ysun.co" "https://*.ysun.co" ];
  csp = frameAncestors: lib.concatStringsSep "; "
    (lib.mapAttrsToList (directive: extra: lib.concatStringsSep " " ([ directive ] ++ site ++ extra))
      {
        base-uri = [ ];
        connect-src = [ "https://api.github.com" ];
        default-src = [ ];
        font-src = [ "data:" ];
        form-action = [ ];
        frame-ancestors = frameAncestors;
        frame-src = [ "https://embed.music.apple.com" ];
        img-src = [ "https://*.basemaps.cartocdn.com" "data:" ];
        script-src = [ "'unsafe-inline'" "'unsafe-eval'" ];
        style-src = [ "'unsafe-inline'" ];
        worker-src = [ "blob:" ];
      }
    ++ [ "report-uri ${report}/csp" "report-to csp" ]) + ";";
  ancestors = lib.concatStringsSep " " ([ "frame-ancestors" ] ++ site) + ";";
  nel = lib.toJSON { report_to = "nel"; max_age = 31536000; include_subdomains = true; failure_fraction = 1.0; };
  endpoints = lib.concatStringsSep ", " (lib.mapAttrsToList (name: path: "${name}=\"${report}${path}\"") { csp = "/reporting-api/csp"; nel = "/nel"; });
in
{
  imports = [ (import ./sigsci.nix args) ];

  config = lib.mkIf config.services.caddy.enable {
    networking.firewall.allowedTCPPorts = [ 443 ];
    networking.firewall.allowedUDPPorts = [ 443 ];

    services.caddy = {
      email = "ysun@hey.com";
      logFormat = "level WARN";
      enableReload = config.services.caddy.enable;
    };

    services.caddy.globalConfig = ''
      admin unix/${config.services.caddy.dataDir}/admin.sock

      auto_https disable_redirects

      grace_period 10s

      servers {
        strict_sni_host on
        timeouts {
          read_header 10s
        }
      }

      metrics { per_host }

      # dns cloudflare {env.CF_API_TOKEN}
      # ech ech.ysun.co

      storage s3 {
        host       {env.S3_HOST}
        bucket     {env.S3_BUCKET}
        access_id  {env.S3_ACCESS_ID}
        secret_key {env.S3_SECRET_KEY}
        prefix     {env.S3_PREFIX}
        insecure   false
      }

      oidc kanidm {
        issuer https://sso.ysun.co/oauth2/openid/caddy
        client_id caddy
        scope openid email profile
        username preferred_username
        authenticate cookie {
          name session
          secret "{env.CADDY_KANIDM_JWT_SECRET}"
          domain ysun.co
          same_site lax
          claim email
        }
      }
    '';

    services.caddy.extraConfig = ''
      (sigsci) {
        ${lib.optionalString config.services.sigsci-agent.enable ''
          sigsci unix ${config.services.sigsci-agent.socket} {
            timeout 250ms
          }
        ''}
      }

      (base) {
        import sigsci

        tls {
          issuer acme {
            profile shortlived

            dns cloudflare {env.CF_API_TOKEN}
            resolvers 2606:4700:4700::1111 1.1.1.1
          }
        }

        encode zstd br gzip

        header {
          >Strict-Transport-Security "max-age=31536000; includeSubDomains; preload"
          >X-Content-Type-Options "nosniff"
          -Last-Modified
          -Server
          -Via
          -X-Powered-By
        }
        header ?Referrer-Policy "strict-origin-when-cross-origin"
      }

      (common) {
        import base
        header ?Content-Security-Policy `${ancestors}`
      }

      (reports) {
        header ?NEL `${nel}`
        header ?Reporting-Endpoints `${endpoints}`
      }

      (reporting) {
        import base
        import reports
        header ?Content-Security-Policy `${csp [ ]}`
      }

      (webring) {
        import base
        import reports
        header ?Content-Security-Policy `${csp [ "https://gskr.ing" ]}`
      }

      # to protect a site:
      # `import auth` in its virtualHost extraConfig
      # add https://<domain>/oauth2/callback to kanidm caddy originUrl
      (auth) {
        header >Cache-Control "private, no-store"
        oidc kanidm {
          allow {
            user *
          }
        }
      }

      # restrict a site to tailnet:
      # `import tailscale` in its virtualHost.extraConfig
      # wrap routes in `handle @tailnet` and add `respond 404`
      (tailscale) {
        @tailnet remote_ip 100.64.0.0/10 fd7a:115c:a1e0::/48
      }
    '';

    services.caddy.virtualHosts."http://${metricsTarget}" = {
      logFormat = lib.mkForce "output discard";
      extraConfig = ''
        bind ::1
        metrics ${metricsPath}
      '';
    };

    services.victoriametrics.prometheusConfig.scrape_configs = lib.mkIf config.services.victoriametrics.enable [{
      job_name = "caddy";
      static_configs = [{ targets = [ metricsTarget ]; }];
      metrics_path = metricsPath;
    }];

    sops.secrets.caddy = {
      owner = config.services.caddy.user;
      group = config.services.caddy.group;
    };

    systemd.services.caddy.serviceConfig = {
      EnvironmentFile = [ config.sops.secrets.caddy.path ];
      AmbientCapabilities = "CAP_NET_BIND_SERVICE";
      # note that do NOT allow https://github.com/nixos/nixpkgs/pull/471670 hardening
    };
  };
}
