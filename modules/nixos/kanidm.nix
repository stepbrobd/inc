{ lib, ... }:

{ config, pkgs, ... }:

let
  hasTag = lib.hasTag config.networking.hostName;
  inherit (lib.blueprint.services.kanidm) domain;
  inherit (config.security.acme.certs.${domain}) directory;
in
{
  config = lib.mkIf (hasTag "kanidm") {
    # since this host bind kanidm to ip addresses advertised by tailscale subnet router
    # we need to limit this to only allow requests from the actual cgnat range and tailscale v6 block
    networking.firewall.extraInputRules = ''
      iifname "${config.services.tailscale.interfaceName}" ip daddr 100.64.0.0/10 tcp dport 636 accept
      iifname "${config.services.tailscale.interfaceName}" ip6 daddr fd7a:115c:a1e0::/48 tcp dport 636 accept
    '';

    environment.systemPackages = [ pkgs.kanidm ];

    services.caddy = {
      enable = true;
      virtualHosts.${domain}.extraConfig = ''
        import common
        import csp
        header  Cache-Control      "private, must-revalidate, max-age=0;"
        header >Cache-Control (.*) "private, must-revalidate, max-age=0;"
        tls "${directory}/fullchain.pem" "${directory}/key.pem"
        reverse_proxy ${config.services.kanidm.provision.instanceUrl} {
          header_up X-Real-IP {http.request.header.CF-Connecting-IP}
          transport http {
              tls_server_name ${domain}
          }
        }
      '';
    };

    sops.secrets."kanidm/passwd".group = "kanidm";
    sops.secrets."kanidm/passwd".mode = "440";
    sops.secrets."kanidm/oauth/cloudflare".group = "kanidm";
    sops.secrets."kanidm/oauth/cloudflare".mode = "440";
    sops.secrets."kanidm/oauth/grafana".group = "kanidm";
    sops.secrets."kanidm/oauth/grafana".mode = "440";
    sops.secrets."kanidm/oauth/hydra".group = "kanidm";
    sops.secrets."kanidm/oauth/hydra".mode = "440";
    sops.secrets."kanidm/oauth/vaultwarden".group = "kanidm";
    sops.secrets."kanidm/oauth/vaultwarden".mode = "440";

    services.kanidm = {
      client.enable = true;
      client.settings.uri = config.services.kanidm.server.settings.origin;

      server.enable = true;
      server.settings = {
        domain = "ysun.co";
        origin = "https://${domain}";
        http_client_address_info.x-forward-for = [ "::1" ];

        ldapbindaddress = "[::]:636";
        bindaddress = "[::1]:8443";

        tls_key = "${directory}/key.pem";
        tls_chain = "${directory}/fullchain.pem";
      };

      provision = {
        enable = true;
        autoRemove = true;
        acceptInvalidCerts = true;
        instanceUrl = "https://[::1]:8443";

        adminPasswordFile = config.sops.secrets."kanidm/passwd".path;
        idmAdminPasswordFile = config.sops.secrets."kanidm/passwd".path;

        groups = {
          "sso.admins" = { };
          "sso.users" = { };

          "calibre.admins" = { };
          "calibre.users" = { };

          "cloudflare.admins" = { };
          "cloudflare.users" = { };

          "hydra.admins" = { };
          "hydra.users" = { };

          "grafana.server-admins" = { };
          "grafana.admins" = { };
          "grafana.editors" = { };
          "grafana.users" = { };

          "vaultwarden.users" = { };

          "caddy.users" = { };
        };

        persons = {
          ysun = {
            displayName = "Yifei";
            legalName = "Yifei Sun";
            mailAddresses = [ "ysun@hey.com" "ysun@stepbrobd.com" "ysun@ysun.co" ];
            groups = [
              "sso.admins"
              "sso.users"

              "calibre.admins"
              "calibre.users"

              "cloudflare.admins"
              "cloudflare.users"

              "hydra.admins"
              "hydra.users"

              "grafana.server-admins"
              "grafana.admins"
              "grafana.editors"
              "grafana.users"

              "vaultwarden.users"

              "caddy.users"
            ];
          };
        };

        systems.oauth2 = {
          cloudflare = {
            displayName = "Cloudflare";
            originUrl = "https://stepbrobd.cloudflareaccess.com/cdn-cgi/access/callback";
            originLanding = "https://stepbrobd.cloudflareaccess.com/";
            basicSecretFile = config.sops.secrets."kanidm/oauth/cloudflare".path;
            preferShortUsername = true;
            scopeMaps."cloudflare.users" = [
              "openid"
              "email"
              "profile"
            ];
          };

          hydra = {
            displayName = "Hydra";
            allowInsecureClientDisablePkce = true;
            originUrl = "https://${lib.blueprint.services.hydra.domain}/oidc-login";
            originLanding = "https://${lib.blueprint.services.hydra.domain}/";
            basicSecretFile = config.sops.secrets."kanidm/oauth/hydra".path;
            preferShortUsername = true;
            scopeMaps."hydra.users" = [
              "openid"
              "email"
              "profile"
              "groups"
            ];
          };

          grafana = {
            displayName = "Grafana";
            originUrl = "https://${lib.blueprint.services.grafana.domain}/login/generic_oauth";
            originLanding = "https://${lib.blueprint.services.grafana.domain}/";
            basicSecretFile = config.sops.secrets."kanidm/oauth/grafana".path;
            preferShortUsername = true;
            scopeMaps."grafana.users" = [
              "openid"
              "email"
              "profile"
            ];
            claimMaps.groups = {
              joinType = "array";
              valuesByGroup = {
                "grafana.server-admins" = [ "server_admin" ];
                "grafana.admins" = [ "admin" ];
                "grafana.editors" = [ "editor" ];
              };
            };
          };

          # public oidc client for caddy-oidc (github.com/relvacode/caddy-oidc)
          # to add a protected site: append https://<domain>/oauth2/callback to originUrl
          # and `import auth` in its caddy virtualHost extraConfig
          caddy = {
            displayName = "Caddy";
            public = true;
            originUrl = [ "https://${lib.blueprint.services.neogrok.domain}/oauth2/callback" ];
            originLanding = "https://${lib.blueprint.services.neogrok.domain}/";
            preferShortUsername = true;
            scopeMaps."caddy.users" = [
              "openid"
              "email"
              "profile"
            ];
          };

          vaultwarden = {
            displayName = "Vaultwarden";
            originUrl = "https://${lib.blueprint.services.vaultwarden.domain}/identity/connect/oidc-signin";
            originLanding = "https://${lib.blueprint.services.vaultwarden.domain}/";
            basicSecretFile = config.sops.secrets."kanidm/oauth/vaultwarden".path;
            scopeMaps."vaultwarden.users" = [
              "openid"
              "email"
              "profile"
            ];
          };
        };
      };
    };

    users.groups.sso.members = [ "caddy" "kanidm" ];
    security.acme.certs.${domain} = {
      inherit domain;
      extraDomainNames = [ "ldap.ysun.co" ];
      group = "sso";
      reloadServices = [ "caddy.service" "kanidm.service" ];
    };
  };
}
