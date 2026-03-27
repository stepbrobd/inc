{ lib, ... }:

{ config, ... }:

let
  inherit (lib) mkIf toString;

  cfg = config.services.glance;
  inherit (lib.blueprint.services.glance) domain;
in
{
  config = mkIf cfg.enable {
    services.caddy = {
      enable = true;

      virtualHosts.${domain} = {
        extraConfig = ''
          import common
          header Cache-Control "public, max-age=600, must-revalidate"
          reverse_proxy ${cfg.settings.server.host}:${toString cfg.settings.server.port}
        '';
      };
    };

    services.glance.settings = {
      server = {
        host = "[::1]";
        port = 30069;
      };
      theme = {
        background-color = "220 16 22";
        contrast-multiplier = 1.2;
        primary-color = "213 37 63";
        positive-color = "92 33 65";
        negative-color = "354 47 56";
      };
      document.head = ''<script defer data-domain="${domain}" src="https://${lib.blueprint.services.plausible.domain}/js/script.file-downloads.hash.outbound-links.js"></script>'';
      branding = {
        hide-footer = true;
        favicon-url = "https://ysun.co/favicon.ico";
        logo-url = "https://ysun.co/favicon.ico";
      };
      pages = [
        {
          name = "Home";
          width = "slim";
          columns = [
            {
              size = "full";
              widgets = [
                {
                  type = "search";
                  autofocus = true;
                  search-engine = "https://kagi.com/search?q={QUERY}";
                }
                {
                  type = "weather";
                  units = "metric";
                  hour-format = "24h";
                  hide-location = false;
                  show-area-name = true;
                  location = "Grenoble, Auvergne-Rhône-Alpes, France";
                }
                {
                  type = "bookmarks";
                  groups = [
                    {
                      links = [
                        { title = "Hey"; url = "https://app.hey.com"; icon = "si:hey"; same-tab = true; }
                        { title = "Tailscale"; url = "https://login.tailscale.com"; icon = "si:tailscale"; same-tab = true; }
                        { title = "Cloudflare"; url = "https://dash.cloudflare.com"; icon = "si:cloudflare"; same-tab = true; }
                        { title = "NextDNS"; url = "https://my.nextdns.io"; icon = "si:nextdns"; same-tab = true; }
                      ];
                    }
                    {
                      links = [
                        { title = "Neptune"; url = "https://app.neptunenetworks.com"; icon = "si:neptune"; same-tab = true; }
                        { title = "Virtua"; url = "https://manager.virtua.cloud"; icon = "si:serverless"; same-tab = true; }
                        { title = "Vultr"; url = "https://my.vultr.com"; icon = "si:vultr"; same-tab = true; }
                        { title = "xTom"; url = "https://vps.hosting/clientarea"; icon = "si:xstate"; same-tab = true; }
                      ];
                    }
                    {
                      links = [
                        { title = "GitHub"; url = "https://github.com"; icon = "si:github"; same-tab = true; }
                        { title = "GitLab"; url = "https://gitlab.com"; icon = "si:gitlab"; same-tab = true; }
                        { title = "SourceHut"; url = "https://git.sr.ht"; icon = "si:sourcehut"; same-tab = true; }
                        { title = "Codeberg"; url = "https://codeberg.org"; icon = "si:codeberg"; same-tab = true; }
                      ];
                    }
                  ];
                }
              ];
            }
          ];
        }
        {
          name = "Monitor";
          width = "slim";
          columns = [
            {
              size = "full";
              widgets = [
                {
                  type = "search";
                  autofocus = true;
                  search-engine = "https://kagi.com/search?q={QUERY}";
                }
                {
                  type = "monitor";
                  title = "Monitor";
                  sites = [
                    { title = "Attic"; url = "https://cache.ysun.co"; icon = "si:googlecloudstorage"; same-tab = true; }
                    { title = "Calibre"; url = "https://read.ysun.co"; icon = "si:calibreweb"; same-tab = true; }
                    { title = "Glance"; url = "https://home.ysun.co"; icon = "si:homepage"; same-tab = true; }
                    { title = "GoLink"; url = "https://go.${lib.blueprint.tailscale.tailnet}"; icon = "si:linktree"; same-tab = true; }
                    { title = "Grafana"; url = "https://otel.ysun.co"; icon = "si:grafana"; same-tab = true; }
                    { title = "Homepage"; url = "https://ysun.co"; icon = "si:googlehome"; same-tab = true; }
                    { title = "Home Assistant"; url = "https://ha.ysun.co"; icon = "si:homeassistant"; same-tab = true; }
                    { title = "Hydra"; url = "https://hydra.ysun.co"; icon = "si:nixos"; same-tab = true; }
                    { title = "Jitsi"; url = "https://meet.ysun.co"; icon = "si:jitsi"; same-tab = true; }
                    { title = "Kanidm"; url = "https://sso.ysun.co"; icon = "si:adblock"; same-tab = true; }
                    { title = "Plausible"; url = "https://stats.ysun.co"; icon = "si:plausibleanalytics"; same-tab = true; }
                    { title = "Tailscale"; url = "https://login.tailscale.com"; icon = "si:tailscale"; same-tab = true; }
                  ];
                }
                {
                  type = "group";
                  widgets = [
                    { type = "lobsters"; limit = 10; collapse-after = 10; }
                    { type = "hacker-news"; limit = 10; collapse-after = 10; }
                  ];
                }
              ];
            }
          ];
        }
        {
          name = "Market";
          width = "slim";
          columns = [
            {
              size = "full";
              widgets = [
                {
                  type = "search";
                  autofocus = true;
                  search-engine = "https://kagi.com/search?q={QUERY}";
                }
                {
                  type = "markets";
                  title = "Market";
                  sort-by = "change";
                  markets = [
                    { symbol = "QQQ"; name = "Nasdaq-100"; }
                    { symbol = "SQQQ"; name = "ProShares UltraPro Short QQQ"; }
                    { symbol = "VOO"; name = "Vanguard S&P 500"; }
                    { symbol = "AAPL"; name = "Apple"; }
                    { symbol = "NET"; name = "Cloudflare"; }
                    { symbol = "FSLY"; name = "Fastly"; }
                    { symbol = "TSM"; name = "TSMC"; }
                    { symbol = "QCOM"; name = "Qualcomm"; }
                    { symbol = "AMD"; name = "AMD"; }
                    { symbol = "INTC"; name = "Intel"; }
                    { symbol = "PLTR"; name = "Palantir"; }
                    { symbol = "ASML"; name = "ASML"; }
                  ];
                }
                {
                  type = "rss";
                  title = "News";
                  style = "detailed-list";
                  feeds = [
                    { url = "https://feeds.bloomberg.com/markets/news.rss"; title = "Bloomberg"; }
                    { url = "https://www.ft.com/rss/home"; title = "Financial Times"; }
                    { url = "https://feeds.content.dowjones.io/public/rss/RSSMarketsMain"; title = "Wall Street Journal"; }
                  ];
                }
              ];
            }
          ];
        }
      ];
    };
  };
}
