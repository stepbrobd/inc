{ lib, ... }:

let
  inherit (lib.terranix) forZone mkPersonalSiteRebind mkPurelyMailRecord;

  bp = lib.blueprint.hosts;

  ipamHosts = lib.filterAttrs (_: h: h ? ipam && h.ipam ? ipv4 && h.ipam ? ipv6) bp;

  comment = host: "${host.providerName} - ${host.meta.city}, ${host.meta.country}";

  zone = "104.161.23.in-addr.arpa";
  zonePrefix = "arpa_in_addr_23_161_104";

  # zone relative ptr name: strip the zone suffix from the full rdns
  zoneRelativeName = addr:
    lib.removeSuffix ".${zone}" (lib.ipv4ToRdns addr);

  # terraform attribute name: zone prefix + zone-relative rdns with dots as underscores
  ipamAttrName = addr:
    "${zonePrefix}_${lib.replaceStrings [ "." ] [ "_" ] (zoneRelativeName addr)}";

  ptrRecords = lib.foldlAttrs
    (acc: name: host: acc // {
      "${ipamAttrName host.ipam.ipv4}" = {
        type = "PTR";
        proxied = false;
        name = zoneRelativeName host.ipam.ipv4;
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

      "${ipamAttrName "23.161.104.17"}" = {
        type = "PTR";
        proxied = false;
        name = zoneRelativeName "23.161.104.17";
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
