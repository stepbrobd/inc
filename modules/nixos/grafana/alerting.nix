{ lib, ... }:

{ config, ... }:

let
  inherit (lib) mkIf elem filter filterAttrs foldlAttrs blueprint;

  dsUid = config.grafana.datasourceUid;

  mkThreshold = { refId, expression, op ? "gt", params ? [ 0 ] }: {
    inherit refId;
    datasourceUid = "__expr__";
    queryType = "";
    relativeTimeRange = { from = 0; to = 0; };
    model = {
      type = "threshold";
      inherit expression;
      conditions = [{
        evaluator = { type = op; inherit params; };
        operator.type = "and";
        query.params = [ ];
        reducer = { type = "last"; params = [ ]; };
      }];
    };
  };

  mkPromQuery = { refId, uid, expr, from ? 600 }: {
    inherit refId;
    datasourceUid = uid;
    queryType = "";
    relativeTimeRange = { inherit from; to = 0; };
    model = {
      datasource = { type = "prometheus"; inherit uid; };
      editorMode = "code";
      inherit expr refId;
      instant = true;
      range = false;
      intervalMs = 1000;
      maxDataPoints = 43200;
    };
  };

  mkLokiQuery = { refId, uid, expr, from ? 600 }: {
    inherit refId;
    datasourceUid = uid;
    queryType = "instant";
    relativeTimeRange = { inherit from; to = 0; };
    model = {
      datasource = { type = "loki"; inherit uid; };
      editorMode = "code";
      queryType = "instant";
      inherit expr refId;
      intervalMs = 1000;
      maxDataPoints = 43200;
    };
  };

  promHosts = filterAttrs (_: h: elem "prometheus" h.tags) blueprint.hosts;
  lokiHosts = filterAttrs (_: h: elem "loki" h.tags) blueprint.hosts;

  mkPromAlerts = name: host:
    let uid = dsUid name "prometheus";
    in [
      {
        uid = "alert-${name}-scrape-down";
        title = "${host.name} - Scrape Target Down";
        condition = "B";
        "for" = "5m";
        annotations.summary = "A scrape target on ${host.name} has been unreachable for 5 minutes";
        data = [
          (mkPromQuery { refId = "A"; inherit uid; expr = "up{} == 0"; })
          (mkThreshold { refId = "B"; expression = "A"; })
        ];
      }
      {
        uid = "alert-${name}-disk-low";
        title = "${host.name} - Disk Space Low";
        condition = "B";
        "for" = "10m";
        annotations.summary = "Root filesystem below 10% free on ${host.name}";
        data = [
          (mkPromQuery { refId = "A"; inherit uid; expr = ''(node_filesystem_avail_bytes{mountpoint="/"} / node_filesystem_size_bytes{mountpoint="/"}) * 100''; })
          (mkThreshold { refId = "B"; expression = "A"; op = "lt"; params = [ 10 ]; })
        ];
      }
      {
        uid = "alert-${name}-systemd-failed";
        title = "${host.name} - Systemd Unit Failed";
        condition = "B";
        "for" = "5m";
        annotations.summary = "A systemd unit on ${host.name} is in failed state";
        data = [
          (mkPromQuery { refId = "A"; inherit uid; expr = ''node_systemd_unit_state{state="failed"}''; })
          (mkThreshold { refId = "B"; expression = "A"; })
        ];
      }
      {
        uid = "alert-${name}-cert-expiry";
        title = "${host.name} - Certificate Expiring Soon";
        condition = "B";
        "for" = "1h";
        annotations.summary = "A TLS certificate on ${host.name} expires within 7 days";
        data = [
          (mkPromQuery { refId = "A"; inherit uid; expr = "(caddy_tls_certificate_not_after - time()) / 86400"; from = 3600; })
          (mkThreshold { refId = "B"; expression = "A"; op = "lt"; params = [ 7 ]; })
        ];
      }
    ];

  mkLokiAlerts = name: host:
    let uid = dsUid name "loki";
    in [
      {
        uid = "alert-${name}-pg-collation";
        title = "${host.name} - PostgreSQL DB Version Mismatch";
        condition = "B";
        "for" = "0s";
        annotations.summary = "PostgreSQL on ${host.name} detected a collation version mismatch requiring ALTER DATABASE REFRESH";
        data = [
          (mkLokiQuery { refId = "A"; inherit uid; expr = ''count by(unit) (rate({unit="postgresql.service"} |~ `ALTER DATABASE .* REFRESH COLLATION VERSION` [$__auto])) or on () vector (0)''; })
          (mkThreshold { refId = "B"; expression = "A"; })
        ];
      }
    ];
in
{
  config = mkIf config.services.grafana.enable {
    services.grafana.provision.alerting.rules.settings = {
      apiVersion = 1;
      groups =
        (foldlAttrs
          (acc: name: host: acc ++ [
            {
              orgId = 1;
              name = "${host.name} - Health";
              folder = "Alerts";
              interval = "1m";
              rules = filter
                (r: elem r.uid [
                  "alert-${name}-scrape-down"
                  "alert-${name}-systemd-failed"
                ])
                (mkPromAlerts name host);
            }
            {
              orgId = 1;
              name = "${host.name} - Resources";
              folder = "Alerts";
              interval = "5m";
              rules = filter (r: r.uid == "alert-${name}-disk-low") (mkPromAlerts name host);
            }
            {
              orgId = 1;
              name = "${host.name} - Certificates";
              folder = "Alerts";
              interval = "1h";
              rules = filter (r: r.uid == "alert-${name}-cert-expiry") (mkPromAlerts name host);
            }
          ]) [ ]
          promHosts)
        ++
        (foldlAttrs
          (acc: name: host: acc ++ [{
            orgId = 1;
            name = "${host.name} - Loki";
            folder = "Alerts";
            interval = "5m";
            rules = mkLokiAlerts name host;
          }]) [ ]
          lokiHosts);
    };
  };
}
