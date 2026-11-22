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
        noDataState = "OK";
        "for" = "5m";
        annotations.summary = "A scrape target on ${host.name} has been unreachable for 5 minutes";
        data = [
          (mkPromQuery { refId = "A"; inherit uid; expr = "up{} == 0"; })
          (mkThreshold { refId = "B"; expression = "A"; })
        ];
      }
      {
        uid = "alert-${name}-rfm-ring-drops";
        title = "${host.name} - RFM Ring Buffer Drops";
        condition = "B";
        noDataState = "OK";
        "for" = "0s";
        annotations.summary = "rfm on ${host.name} dropped sampled events from the ring buffer in the last 10 minutes, the collector could not keep up";
        data = [
          (mkPromQuery { refId = "A"; inherit uid; expr = "increase(rfm_collector_dropped_events_total[10m])"; })
          (mkThreshold { refId = "B"; expression = "A"; })
        ];
      }
      {
        uid = "alert-${name}-rfm-forced-evictions";
        title = "${host.name} - RFM Flow Table Full";
        condition = "B";
        noDataState = "OK";
        "for" = "0s";
        annotations.summary = "rfm on ${host.name} forced flows out of a full table in the last 10 minutes, likely a scan";
        data = [
          (mkPromQuery { refId = "A"; inherit uid; expr = "increase(rfm_collector_forced_evictions_total[10m])"; })
          (mkThreshold { refId = "B"; expression = "A"; })
        ];
      }
      {
        uid = "alert-${name}-rfm-ipfix-errors";
        title = "${host.name} - RFM IPFIX Export Errors";
        condition = "B";
        noDataState = "OK";
        "for" = "0s";
        annotations.summary = "rfm on ${host.name} lost IPFIX records in the last 10 minutes, check rfm_ipfix_send_errors_total by errno";
        data = [
          (mkPromQuery { refId = "A"; inherit uid; expr = ''increase(rfm_errors_total{subsystem="ipfix"}[10m])''; })
          (mkThreshold { refId = "B"; expression = "A"; })
        ];
      }
      {
        uid = "alert-${name}-conntrack-full";
        title = "${host.name} - Conntrack Table Nearly Full";
        condition = "B";
        noDataState = "OK";
        "for" = "5m";
        annotations.summary = "conntrack on ${host.name} is above 90 percent of nf_conntrack_max, new connections and exports will be dropped";
        data = [
          (mkPromQuery { refId = "A"; inherit uid; expr = "node_nf_conntrack_entries / node_nf_conntrack_entries_limit * 100"; })
          (mkThreshold { refId = "B"; expression = "A"; params = [ 90 ]; })
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
    services.grafana.provision.alerting.policies.settings = {
      apiVersion = 1;
      policies = [{
        orgId = 1;
        receiver = "Discord";
        group_by = [ "grafana_folder" "alertname" ];
      }];
    };

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
              name = "${host.name} - Flow Monitor";
              folder = "Alerts";
              interval = "1m";
              rules = filter
                (r: elem r.uid [
                  "alert-${name}-rfm-ring-drops"
                  "alert-${name}-rfm-forced-evictions"
                  "alert-${name}-rfm-ipfix-errors"
                  "alert-${name}-conntrack-full"
                ])
                (mkPromAlerts name host);
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
