{ lib, ... }:

{ config, ... }:

let
  inherit (lib) mkIf filterAttrs foldlAttrs elem toLower blueprint;

  # deterministic UID shared between datasource provisioning and alert rules
  # e.g. dsUid "halti" "prometheus" -> "datasource-halti-prometheus"
  dsUid = name: type: "datasource-${name}-${type}";

  mkDatasources = label: jsonData:
    let type = toLower label;
    in foldlAttrs
      (acc: name: host: acc ++ [{
        uid = dsUid name type;
        inherit type jsonData;
        name = "${host.name} - ${label}";
        url = "https://${name}.${blueprint.tailscale.tailnet}/${type}";
        access = "proxy";
      }]) [ ]
      (filterAttrs (_: h: elem type h.tags) blueprint.hosts);
in
{
  # re export for alerting.nix
  options.grafana.datasourceUid = lib.mkOption {
    type = lib.types.raw;
    default = dsUid;
    readOnly = true;
  };

  config = mkIf config.services.grafana.enable {
    services.grafana.provision.datasources.settings = {
      apiVersion = 1;
      datasources = mkDatasources "Prometheus" { httpMethod = "POST"; } ++ mkDatasources "Loki" { manageAlerts = false; maxLines = 1000000; };
    };
  };
}
