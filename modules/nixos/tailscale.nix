{ lib, ... }:

{ config, pkgs, ... }:

let
  hasTag = lib.hasTag config.networking.hostName;
in
{
  services.tailscale = {
    openFirewall = true;
    disableUpstreamLogging = true;

    useRoutingFeatures = "both";

    permitCertUid =
      if config.services.caddy.enable
      then config.services.caddy.user
      else null;

    extraSetFlags = [
      "--accept-dns"
      "--accept-routes=false"
      "--advertise-exit-node${if !hasTag "server" then "=false" else ""}"
      "--auto-update=false"
      "--exit-node-allow-lan-access"
      "--hostname=${config.networking.hostName}"
      "--ssh=false"
    ] ++ pkgs.lib.optionals config.services.victoriametrics.enable [
      "--webclient"
    ];
  };

  # in case nftables is used
  systemd.services.tailscaled.environment.TS_DEBUG_FIREWALL_MODE = config.networking.firewall.package.pname;

  # tailscaled netlink monitor logs every foreign table route event
  # ranet babel metrics churn makes it spam journal
  systemd.services.tailscaled.serviceConfig.LogFilterPatterns = [ "~^monitor: RTM_(NEW|DEL)ROUTE" ];

  # scrape tailscale metrics
  services.victoriametrics.prometheusConfig.scrape_configs = pkgs.lib.mkIf config.services.victoriametrics.enable [{
    job_name = "tailscale";
    static_configs = [{ targets = [ "100.100.100.100:80" ]; }];
    metrics_path = "/metrics";
  }];
}
