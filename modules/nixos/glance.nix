{ lib, ... }:

{ config, ... }:

let
  inherit (lib) mkIf toString;

  cfg = config.services.glance;
  hasTag = lib.hasTag config.networking.hostName;
  inherit (lib.blueprint.services.glance) domain;

  # per ASN prefix visibility from bgp.tools (scraped by victoriametrics)
  bgptools = asn: {
    type = "custom-api";
    title = "AS${asn}";
    title-url = "https://bgp.tools/as/${asn}";
    cache = "5m";
    url = "http://${config.services.victoriametrics.listenAddress}/api/v1/query";
    parameters.query = ''bgptools_asn_prefix_visible{asn="${asn}"}'';
    template = ''
      <ul class="list list-gap-4">
      {{ range sortByString "metric.prefix" "asc" (.JSON.Array "data.result") }}
        <li class="flex justify-between">
          <span>{{ .String "metric.prefix" }}</span>
          <span class="color-highlight">{{ .String "value.1" }} feeds</span>
        </li>
      {{ end }}
      </ul>
    '';
  };
in
{
  config = lib.mkMerge [
    (mkIf (hasTag "glance") {
      services.glance.enable = lib.mkDefault true;
    })
    (mkIf cfg.enable {
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
        document.head = ''
          <script defer data-domain="${domain}" src="https://${lib.blueprint.services.plausible.domain}/js/script.file-downloads.hash.outbound-links.js"></script>
          <style>
            /* side by side widgets share the row's width and height */
            .widget-type-split-column .masonry-column { min-width: 0; }
            .widget-type-split-column .masonry-column > .widget { flex: 1; display: flex; flex-direction: column; }
            .widget-type-split-column .masonry-column > .widget > .widget-content { flex: 1; }
          </style>
        '';
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
                    location = "Grenoble, Rhône-Alpes, France";
                  }
                  {
                    type = "bookmarks";
                    groups = [
                      {
                        links = [
                          { title = "Tailscale"; url = "https://login.tailscale.com"; icon = "si:tailscale"; same-tab = true; }
                          { title = "Fastly"; url = "https://manage.fastly.com"; icon = "si:fastly"; same-tab = true; }
                          { title = "Cloudflare"; url = "https://dash.cloudflare.com"; icon = "si:cloudflare"; same-tab = true; }
                          { title = "NextDNS"; url = "https://my.nextdns.io"; icon = "si:nextdns"; same-tab = true; }
                        ];
                      }
                      {
                        links = [
                          { title = "Neptune"; url = "https://app.neptunenetworks.com"; icon = "si:opennebula"; same-tab = true; }
                          { title = "Virtua"; url = "https://manager.virtua.cloud"; icon = "si:qemu"; same-tab = true; }
                          { title = "Vultr"; url = "https://my.vultr.com"; icon = "si:vultr"; same-tab = true; }
                          { title = "xTom"; url = "https://vps.hosting/clientarea"; icon = "si:proxmox"; same-tab = true; }
                        ];
                      }
                      {
                        links = [
                          { title = "NetActuate"; url = "https://netactuate.com"; icon = "si:vmware"; same-tab = true; }
                          { title = "AWS"; url = "https://console.aws.amazon.com/console/home/"; icon = "si:openstack"; same-tab = true; }
                          { title = "Misaka"; url = "https://app.misaka.io"; icon = "si:virtualbox"; same-tab = true; }
                          { title = "GitHub"; url = "https://github.com"; icon = "si:github"; same-tab = true; }
                        ];
                      }
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
                      { title = "Homepage"; url = "https://ysun.co"; icon = "si:googlehome"; same-tab = true; }
                      { title = "Time"; url = "https://time.ysun.co"; icon = "si:clockify"; same-tab = true; }
                      { title = "Cache"; url = "https://cache.ysun.co"; check-url = "https://cache.ysun.co/nix-cache-info"; icon = "si:nixos"; same-tab = true; }
                      { title = "Jitsi"; url = "https://meet.ysun.co"; icon = "si:jitsi"; same-tab = true; }
                      { title = "Plausible"; url = "https://stats.ysun.co"; icon = "si:plausibleanalytics"; same-tab = true; }
                      { title = "Grafana"; url = "https://otel.ysun.co"; icon = "si:grafana"; same-tab = true; }
                      { title = "Kanidm"; url = "https://sso.ysun.co"; icon = "si:openid"; same-tab = true; }
                      { title = "Vaultwarden"; url = "https://vault.ysun.co"; icon = "si:vaultwarden"; same-tab = true; }
                      { title = "Paperless"; url = "https://dms.ysun.co"; icon = "si:paperlessngx"; same-tab = true; }
                      { title = "Home Assistant"; url = "https://ha.ysun.co"; icon = "si:homeassistant"; same-tab = true; }
                      { title = "Kavita"; url = "https://read.ysun.co"; icon = "si:calibreweb"; same-tab = true; }
                      { title = "Glance"; url = "https://home.ysun.co"; icon = "si:glance"; same-tab = true; }
                    ];
                  }
                  {
                    type = "split-column";
                    widgets = [ (bgptools "10779") (bgptools "18932") ];
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
    })
  ];
}
