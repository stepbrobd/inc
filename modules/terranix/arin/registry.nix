{ lib, ... }:

let
  inherit (lib) listToAttrs map nameValuePair zoneSlug;
  inherit (lib.terranix) tfRef;

  # ARIN stores nameserver host names in uppercase
  nameservers = [
    "NS.YSUN.CO"
    "NS.YSUN.FR"
    "NS.YSUN.JP"
    "NS.YSUN.US"
  ];

  # RFC9092 geofeed url in public comment
  comment = [
    "https://stepbrobd.com"
    "Geofeed https://stepbrobd.com/geofeed.csv"
  ];

  # reverse zones delegated at arin, hosted as cloudflare zones in this config
  zones = [
    "0.0.9.5.f.2.0.6.2.ip6.arpa"
    "104.161.23.in-addr.arpa"
    "136.104.192.in-addr.arpa"
    "20.115.204.in-addr.arpa"
    "21.115.204.in-addr.arpa"
  ];

  forZones = f: listToAttrs (map (zone: nameValuePair (zoneSlug zone) (f zone)) zones);
in
{
  # nets are adopt-only and import by handle
  # e.g. `tofu import arin_net.net_23_161_104_0_1 NET-23-161-104-0-1`
  # only net_name and comment are updatable
  resource.arin_net = {
    net6_2602_f590_1 = {
      handle = "NET6-2602-F590-1";
      net_name = "STEPBROBD";
      inherit comment;
    };

    net_192_104_136_0_1 = {
      handle = "NET-192-104-136-0-1";
      net_name = "STEPBROBD";
      inherit comment;
    };

    net_23_161_104_0_1 = {
      handle = "NET-23-161-104-0-1";
      net_name = "STEPBROBD";
      inherit comment;
    };

    net_204_115_20_0_1 = {
      handle = "NET-204-115-20-0-1";
      net_name = "STEPBROBD";
      inherit comment;
    };
  };

  # DS components mirror cloudflare dnssec settings on corresponding zone
  data.cloudflare_zone_dnssec = forZones (zone: {
    zone_id = ''''${data.sops_file.secrets.data["cloudflare.zone_id.${zone}"]}'';
  });

  # delegations exist per net and are modified in place
  # cloudflare serves the digest lowercase while arin matches uppercase
  resource.arin_delegation = forZones (zone: {
    name = zone;
    inherit nameservers;
    delegation_keys = [{
      algorithm = tfRef "tonumber(data.cloudflare_zone_dnssec.${zoneSlug zone}.algorithm)";
      digest = tfRef "upper(data.cloudflare_zone_dnssec.${zoneSlug zone}.digest)";
      digest_type = tfRef "tonumber(data.cloudflare_zone_dnssec.${zoneSlug zone}.digest_type)";
      key_tag = tfRef "data.cloudflare_zone_dnssec.${zoneSlug zone}.key_tag";
      ttl = 3600;
    }];
  });
}
