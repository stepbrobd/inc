{ lib, ... }:

let
  inherit (lib.terranix) forZone mkPersonalSiteRebind mkPurelyMailRecord tfRef;

  bp = lib.blueprint.hosts;

  # hosts with IPAM addresses
  ipamHosts = lib.filterAttrs (_: h: h ? ipam && h.ipam ? ipv4 && h.ipam ? ipv6) bp;

  # hosts with provider addresses
  ifHosts = lib.filterAttrs (_: h: h ? ipv4 && h.ipv4 != null && h ? ipv6 && h.ipv6 != null) bp;

  comment = host: "${host.providerName} - ${host.meta.city}, ${host.meta.country}";

  # *.sd.ysun.co IPAM addresses only
  sdRecords = lib.foldlAttrs
    (acc: name: host: acc // {
      "co_ysun_sd_${name}_v4" = {
        type = "A";
        proxied = false;
        name = "${name}.sd";
        content = host.ipam.ipv4;
        comment = comment host;
      };
      "co_ysun_sd_${name}_v6" = {
        type = "AAAA";
        proxied = false;
        name = "${name}.sd";
        content = host.ipam.ipv6;
        comment = comment host;
      };
    })
    { }
    ipamHosts;

  # *.if.ysun.co provider interface addresses only
  ifRecords = lib.foldlAttrs
    (acc: name: host: acc // {
      "co_ysun_if_${name}_v4" = {
        type = "A";
        proxied = false;
        name = "${name}.if";
        content = host.ipv4;
        comment = comment host;
      };
      "co_ysun_if_${name}_v6" = {
        type = "AAAA";
        proxied = false;
        name = "${name}.if";
        content = host.ipv6;
        comment = comment host;
      };
    })
    { }
    ifHosts;
in
{
  resource.cloudflare_dns_record = forZone "ysun.co"
    ({
      # dependency: all sites using `lib.terranix.mkPersonalSiteRebind`
      co_ysun_apex_v4 = {
        type = "A";
        proxied = false;
        name = "@";
        content = "23.161.104.17";
        comment = "AS10779 - Anycast - Personal Site";
      };
      co_ysun_apex_v6 = {
        type = "AAAA";
        proxied = false;
        name = "@";
        content = "2602:f590::23:161:104:17";
        comment = "AS10779 - Anycast - Personal Site";
      };
      co_ysun_wildcard = mkPersonalSiteRebind { name = "*"; };

      co_ysun_srvc = {
        type = "HTTPS";
        proxied = false;
        name = "@";
        data = {
          priority = 1;
          target = ".";
          value = lib.concatStringsSep " " [
            ''alpn="h3,h2"''
            (''ipv4hint="'' + tfRef "cloudflare_dns_record.co_ysun_apex_v4.content" + ''"'')
            (''ipv6hint="'' + tfRef "cloudflare_dns_record.co_ysun_apex_v6.content" + ''"'')
          ];
        };
        comment = "HTTPS Service Binding - Personal Site";
      };
    }
    //
    sdRecords
    //
    ifRecords
    //
    mkPurelyMailRecord "ysun.co" "co_ysun"
    //
    {
      # service CNAME records
      co_ysun_cache = {
        type = "CNAME";
        proxied = false;
        name = "cache";
        content = "odake.sd.ysun.co";
        comment = "SSDNodes - Tokyo 2 - Hydra";
      };

      co_ysun_ha = {
        type = "CNAME";
        proxied = false;
        name = "ha";
        content = "isere.ts.ysun.co";
        comment = "Tailscale Internal - Raspberry Pi - Home Assistant";
      };

      co_ysun_home = {
        type = "CNAME";
        proxied = false;
        name = "home";
        content = "walberla.sd.ysun.co";
        comment = "Hetzner - Glance";
      };

      co_ysun_hydra = {
        type = "CNAME";
        proxied = false;
        name = "hydra";
        content = "odake.sd.ysun.co";
        comment = "SSDNodes - Tokyo 2 - Hydra";
      };

      co_ysun_ldap = {
        type = "CNAME";
        proxied = false;
        name = "ldap";
        content = "walberla.ts.ysun.co";
        comment = "Hetzner - Kanidm";
      };

      # dependency: cloudflare_dns_record.fr_grenug_meet
      co_ysun_meet = {
        type = "CNAME";
        proxied = false;
        name = "meet";
        content = "lagern.sd.ysun.co";
        comment = "AWS - EU Central 2 - Jitsi Meet";
      };

      co_ysun_grep = {
        type = "CNAME";
        proxied = false;
        name = "grep";
        content = "odake.sd.ysun.co";
        comment = "SSDNodes - Tokyo 2 - Neogrok";
      };

      co_ysun_otel = {
        type = "CNAME";
        proxied = false;
        name = "otel";
        content = "halti.sd.ysun.co";
        comment = "Garnix - Grafana";
      };

      co_ysun_read = {
        type = "CNAME";
        proxied = false;
        name = "read";
        content = "toompea.sd.ysun.co";
        comment = "V.PS - Tallinn, Estonia - Calibre";
      };

      co_ysun_sso = {
        type = "CNAME";
        proxied = false;
        name = "sso";
        content = "walberla.sd.ysun.co";
        comment = "Hetzner - Kanidm";
      };

      co_ysun_stats = {
        type = "CNAME";
        proxied = false;
        name = "stats";
        content = "toompea.sd.ysun.co";
        comment = "V.PS - Tallinn, Estonia - Plausible Analytics";
      };

      co_ysun_tailscale = {
        type = "TXT";
        proxied = false;
        name = "@";
        content = ''"TAILSCALE-aF1t4amerhfObdf0vkPl"'';
        comment = "Tailscale - Verification";
      };

      co_ysun_time = {
        type = "CNAME";
        proxied = false;
        name = "time";
        content = "isere.sd.ysun.co";
        comment = "Raspberry Pi - Time Server";
      };

      co_ysun_vault = {
        type = "CNAME";
        proxied = false;
        name = "vault";
        content = "isere.ts.ysun.co";
        comment = "Tailscale Internal - Raspberry Pi - Vaultwarden";
      };

      co_ysun_google = {
        type = "TXT";
        proxied = false;
        name = "@";
        content = ''"google-site-verification=2LutjaV7j2eFT1GaPS5YcbRM5QrX-pZsvzNOYK4i-mQ"'';
        comment = "Google - Search Console";
      };

      co_ysun_cloudflare = {
        type = "TXT";
        proxied = false;
        name = "@";
        content = ''"cloudflare_dashboard_sso=16225a3c3e10d1b53d78b2e3886f8a99"'';
        comment = "Cloudflare - SSO Verification";
      };
    });
}
