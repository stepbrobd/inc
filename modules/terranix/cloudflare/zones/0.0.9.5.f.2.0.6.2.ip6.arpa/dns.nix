{ lib, ... }:

let
  inherit (lib.terranix) forZone mkPersonalSiteRebind mkPurelyMailRecord;

  bp = lib.blueprint.hosts;

  ipamHosts = lib.filterAttrs (_: h: h ? ipam && h.ipam ? ipv4 && h.ipam ? ipv6) bp;

  comment = host: "${host.providerName} - ${host.meta.city}, ${host.meta.country}";

  zone = "0.0.9.5.f.2.0.6.2.ip6.arpa";
  zonePrefix = "arpa_ip6_2_6_0_2_f_5_9_0_0";

  # zone relative ptr name: strip the zone suffix from the full rdns
  zoneRelativeName = addr:
    lib.removeSuffix ".${zone}" (lib.ipv6ToRdns addr);

  # terraform attribute name: zone prefix + zone-relative rdns with dots as underscores
  ipamAttrName = addr:
    "${zonePrefix}_${lib.replaceStrings [ "." ] [ "_" ] (zoneRelativeName addr)}";

  ptrRecords = lib.foldlAttrs
    (acc: name: host: acc // {
      "${ipamAttrName host.ipam.ipv6}" = {
        type = "PTR";
        proxied = false;
        name = zoneRelativeName host.ipam.ipv6;
        content = "${name}.sd.ysun.co";
        comment = comment host;
      };
    })
    { }
    ipamHosts;
in
{
  resource.cloudflare_dns_record = forZone zone
    ({
      "${zonePrefix}_apex" = mkPersonalSiteRebind { name = "@"; proxied = false; };

      "${ipamAttrName "2602:f590::23:161:104:17"}" = {
        type = "PTR";
        proxied = false;
        name = zoneRelativeName "2602:f590::23:161:104:17";
        content = "ysun.co";
        comment = "AS10779 - Anycast";
      };
    }
    //
    ptrRecords
    //
    mkPurelyMailRecord zone zonePrefix
    );
}
