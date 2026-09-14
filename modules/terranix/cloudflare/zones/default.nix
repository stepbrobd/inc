{ lib, ... } @ args:

{ ... }:

let
  inherit (lib) attrNames concatMap deepMergeAttrsList filter map readDir;
  inherit (lib.terranix) mkZoneSettingResources;

  zones = filter (f: f != "default.nix") (attrNames (readDir ./.));
in
{
  imports = concatMap
    (f: [
      (import ./${f}/dns.nix args)
      (import ./${f}/zone.nix args)
    ])
    zones;

  # common zone settings applied unconditionally
  resource.cloudflare_zone_setting = deepMergeAttrsList (map mkZoneSettingResources zones);

  # uniform url normalization on all zones (incoming and to origin)
  resource.cloudflare_url_normalization_settings = deepMergeAttrsList (map
    (zone: {
      "${lib.zoneSlug zone}_url_normalization" = {
        zone_id = ''''${data.sops_file.secrets.data["cloudflare.zone_id.${zone}"]}'';
        type = "cloudflare";
        scope = "both";
      };
    })
    zones);

  # disable ai bot blocking and cloudflare managed robots.txt
  resource.cloudflare_bot_management = deepMergeAttrsList (map
    (zone: {
      "${lib.zoneSlug zone}_bot_management" = {
        zone_id = ''''${data.sops_file.secrets.data["cloudflare.zone_id.${zone}"]}'';
        ai_bots_protection = "disabled";
        crawler_protection = "disabled";
        is_robots_txt_managed = false;
      };
    })
    zones);

  # pin dnssec enabled
  resource.cloudflare_zone_dnssec = deepMergeAttrsList (map
    (zone: {
      "${lib.zoneSlug zone}_dnssec" = {
        zone_id = ''''${data.sops_file.secrets.data["cloudflare.zone_id.${zone}"]}'';
        status = "active";
      };
    })
    zones);

  # tiered cache
  resource.cloudflare_argo_tiered_caching = deepMergeAttrsList (map
    (zone: {
      "${lib.zoneSlug zone}_argo_tiered_caching" = {
        zone_id = ''''${data.sops_file.secrets.data["cloudflare.zone_id.${zone}"]}'';
        value = "on";
      };
    })
    zones);

  # turn universal ssl off
  # might need to turn this back on if a record need to set proxied
  resource.cloudflare_universal_ssl_setting = deepMergeAttrsList (map
    (zone: {
      "${lib.zoneSlug zone}_universal_ssl" = {
        zone_id = ''''${data.sops_file.secrets.data["cloudflare.zone_id.${zone}"]}'';
        enabled = false;
      };
    })
    zones);

  # turn total tls off
  resource.cloudflare_total_tls = deepMergeAttrsList (map
    (zone: {
      "${lib.zoneSlug zone}_total_tls" = {
        zone_id = ''''${data.sops_file.secrets.data["cloudflare.zone_id.${zone}"]}'';
        enabled = false;
      };
    })
    zones);

  # smart tiered cache
  resource.cloudflare_tiered_cache = deepMergeAttrsList (map
    (zone: {
      "${lib.zoneSlug zone}_tiered_cache" = {
        zone_id = ''''${data.sops_file.secrets.data["cloudflare.zone_id.${zone}"]}'';
        value = "on";
      };
    })
    zones);
}
