{ lib, ... }:

{ config, ... }:

let
  inherit (lib) mkIf mkMerge mkAfter mkForce toString;

  hasTag = lib.hasTag config.networking.hostName;
  hasProm = hasTag "prometheus";
  hasLoki = hasTag "loki";
  tsDomain = "${config.networking.hostName}.${lib.blueprint.tailscale.tailnet}";
in
{
  # "prometheus" tag: VictoriaMetrics (drop in prometheus replacement) + node exporter + RFM
  # "loki" tag: Loki + Fluent Bit (promtail replacement) + geoip enrichment
  config = mkMerge [
    (mkIf hasProm {
      # rfm binds to my own prefix address for ipfix export
      # which requires ranet tunnels to be established
      # space out retries on slow boots
      systemd.services.rfm.serviceConfig = {
        RestartSec = 5;
        StartLimitBurst = 20;
      };

      services.rfm =
        let
          host = lib.blueprint.hosts.${config.networking.hostName};
        in
        {
          enable = true;
          settings.agent = {
            interfaces = [ host.interface ];
            # should match cloudflare magic network monitoring default_sampling
            # see cloudflare terranix module
            bpf.sample_rate = 10;
            prometheus.host = "::1";
            prometheus.port = 9669;
            enrich.mmdb.asn_db = "${config.services.geoipupdate.settings.DatabaseDirectory}/GeoLite2-ASN.mmdb";
            enrich.mmdb.city_db = "${config.services.geoipupdate.settings.DatabaseDirectory}/GeoLite2-City.mmdb";
            ipfix.bind.host = host.ipam.ipv4 or host.ipv4;
            ipfix.host = "162.159.65.1";
            ipfix.port = 2055;
          };
        };

      # node exporter uses the prometheus NixOS module's exporter subsystem
      # (works independently of services.prometheus.enable)
      services.prometheus.exporters.node = {
        enable = true;
        enabledCollectors = [ "systemd" ];
        listenAddress = "[::1]";
        port = 9100;
      };

      services.victoriametrics = {
        enable = true;
        listenAddress = "[::1]:8428";
        retentionPeriod = "6M";
        extraOptions = [
          "-enableTCP6"
          "-memory.allowedPercent=40"
          "-search.maxConcurrentRequests=2"
        ];
        prometheusConfig.global.scrape_interval = "30s";
        prometheusConfig.scrape_configs = [
          {
            job_name = "node";
            static_configs = [{
              targets = [ "${config.services.prometheus.exporters.node.listenAddress}:${toString config.services.prometheus.exporters.node.port}" ];
            }];
          }
          {
            job_name = "rfm";
            static_configs = [{
              targets = [ "[${config.services.rfm.settings.agent.prometheus.host}]:${toString config.services.rfm.settings.agent.prometheus.port}" ];
            }];
          }
        ];
      };

      services.geoipupdate.enable = true;

      services.caddy = {
        enable = true;
        virtualHosts.${tsDomain}.extraConfig = mkAfter ''
          handle_path /prometheus/* {
            reverse_proxy [::1]:8428
          }
        '';
      };
    })

    (mkIf hasLoki {
      services.loki = {
        enable = true;
        extraFlags = [ "-print-config-stderr" ];

        configuration = {
          analytics.reporting_enabled = false;
          auth_enabled = false;

          server = {
            http_listen_address = "::1";
            http_listen_port = 3100;
            grpc_listen_port = 0;
          };

          ingester = {
            lifecycler = {
              address = "::1";
              ring = {
                kvstore.store = "inmemory";
                replication_factor = 1;
              };
            };
            chunk_idle_period = "1h";
            max_chunk_age = "1h";
            chunk_target_size = 999999;
            chunk_retain_period = "30s";
          };

          schema_config.configs = [{
            from = "2024-04-01";
            object_store = "filesystem";
            store = "tsdb";
            schema = "v13";
            index = {
              prefix = "index_";
              period = "24h";
            };
          }];

          storage_config = with config.services.loki; {
            filesystem.directory = "${dataDir}/chunks";
            tsdb_shipper = {
              active_index_directory = "${dataDir}/tsdb-index";
              cache_location = "${dataDir}/tsdb-cache";
              cache_ttl = "24h";
            };
          };

          limits_config = {
            reject_old_samples = true;
            reject_old_samples_max_age = "168h";
          };

          compactor = {
            working_directory = config.services.loki.dataDir;
            compactor_ring.kvstore.store = "inmemory";
          };
        };
      };

      # expose loki metrics to VictoriaMetrics when both tags are present
      services.victoriametrics.prometheusConfig.scrape_configs = lib.mkIf hasProm [{
        job_name = "loki";
        static_configs = [{
          targets = [ "[${config.services.loki.configuration.server.http_listen_address}]:${toString config.services.loki.configuration.server.http_listen_port}" ];
        }];
      }];

      services.fluent-bit = {
        enable = true;
        settings = {
          service = {
            flush = 5;
            log_level = "warn";
          };

          pipeline = {
            inputs = [{
              name = "systemd";
              tag = "journal";
              read_from_tail = true;
              strip_underscores = true;
              db = "/var/lib/fluent-bit/journal.db";
              max_entries = 1000;
            }];

            filters = [
              {
                name = "modify";
                match = "journal";
                rename = "SYSTEMD_UNIT unit";
              }
              {
                name = "parser";
                match = "journal";
                key_name = "MESSAGE";
                parser = "extract_ip";
                reserve_data = true;
                preserve_key = true;
              }
              {
                name = "geoip2";
                match = "journal";
                database = "${config.services.geoipupdate.settings.DatabaseDirectory}/GeoLite2-City.mmdb";
                lookup_key = "ip";
                record = [
                  "geo_city ip %{city.names.en}"
                  "geo_country ip %{country.names.en}"
                  "geo_country_code ip %{country.iso_code}"
                  "geo_latitude ip %{location.latitude}"
                  "geo_longitude ip %{location.longitude}"
                ];
              }
            ];

            outputs = [{
              name = "loki";
              match = "journal";
              host = "::1";
              port = config.services.loki.configuration.server.http_listen_port;
              labels = "job=systemd-journal, host=${config.networking.hostName}";
              label_keys = "$unit";
              line_format = "json";
              remove_keys = "$discard_before, $discard_after";
            }];
          };

          parsers = [{
            name = "extract_ip";
            format = "regex";
            regex = lib.concatStrings [
              ''(?<discard_before>.*?)''
              ''(?<ip>''
              # ipv4
              ''(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)''
              "|"
              # ipv6: full form
              ''(?:[0-9a-fA-F]{1,4}:){7}[0-9a-fA-F]{1,4}''
              "|"
              # ipv6: ::suffix (1-7 groups)
              '':(?::[0-9a-fA-F]{1,4}){1,7}''
              "|"
              # ipv6: prefix:: (1-7 groups)
              ''(?:[0-9a-fA-F]{1,4}:){1,7}:''
              "|"
              # ipv6: prefix::suffix (total <= 7 groups)
              ''(?:[0-9a-fA-F]{1,4}:){1,6}:[0-9a-fA-F]{1,4}''
              "|"
              ''(?:[0-9a-fA-F]{1,4}:){1,5}(?::[0-9a-fA-F]{1,4}){1,2}''
              "|"
              ''(?:[0-9a-fA-F]{1,4}:){1,4}(?::[0-9a-fA-F]{1,4}){1,3}''
              "|"
              ''(?:[0-9a-fA-F]{1,4}:){1,3}(?::[0-9a-fA-F]{1,4}){1,4}''
              "|"
              ''(?:[0-9a-fA-F]{1,4}:){1,2}(?::[0-9a-fA-F]{1,4}){1,5}''
              "|"
              ''[0-9a-fA-F]{1,4}:(?::[0-9a-fA-F]{1,4}){1,6}''
              "|"
              # ipv6: bare ::
              ''::''
              '')''
              ''(?<discard_after>.*)''
            ];
          }];
        };
      };

      systemd.services.fluent-bit.serviceConfig.StateDirectory = "fluent-bit";

      services.geoipupdate.enable = true;

      services.caddy = {
        enable = true;
        virtualHosts.${tsDomain}.extraConfig = mkAfter ''
          handle_path /loki/* {
            reverse_proxy [${config.services.loki.configuration.server.http_listen_address}]:${toString config.services.loki.configuration.server.http_listen_port}
          }
        '';
      };
    })

    (mkIf (hasProm || hasLoki) {
      services.caddy.virtualHosts.${tsDomain}.logFormat = mkForce "output discard";
    })
  ];
}
