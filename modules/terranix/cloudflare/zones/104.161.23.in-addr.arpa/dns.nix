{ lib, ... }:

let
  inherit (lib.terranix) forZone mkPersonalSiteRebind mkPurelyMailRecord;
in
{
  resource.cloudflare_dns_record = forZone "104.161.23.in-addr.arpa"
    {
      arpa_in_addr_23_161_104_apex = mkPersonalSiteRebind { name = "@"; proxied = false; };

      arpa_in_addr_23_161_104_17 = {
        type = "PTR";
        proxied = false;
        name = "17";
        content = "ysun.co";
        comment = "AS10779 - Anycast";
      };

      arpa_in_addr_23_161_104_128 = {
        type = "PTR";
        proxied = false;
        name = "128";
        content = "toompea.sd.ysun.co";
        comment = "xTom - Tallinn, Estonia";
      };

      arpa_in_addr_23_161_104_129 = {
        type = "PTR";
        proxied = false;
        name = "129";
        content = "highline.sd.ysun.co";
        comment = "Neptune - New York";
      };

      arpa_in_addr_23_161_104_130 = {
        type = "PTR";
        proxied = false;
        name = "130";
        content = "kongo.sd.ysun.co";
        comment = "Vultr - Osaka";
      };

      arpa_in_addr_23_161_104_131 = {
        type = "PTR";
        proxied = false;
        name = "131";
        content = "timah.sd.ysun.co";
        comment = "Misaka - Singapore";
      };

      arpa_in_addr_23_161_104_132 = {
        type = "PTR";
        proxied = false;
        name = "132";
        content = "butte.sd.ysun.co";
        comment = "Virtua - Paris";
      };

      arpa_in_addr_23_161_104_133 = {
        type = "PTR";
        proxied = false;
        name = "133";
        content = "isere.sd.ysun.co";
        comment = "Raspberry Pi 5B - Grenoble";
      };

      arpa_in_addr_23_161_104_134 = {
        type = "PTR";
        proxied = false;
        name = "134";
        content = "halti.sd.ysun.co";
        comment = "Garnix - Hosting";
      };

      arpa_in_addr_23_161_104_135 = {
        type = "PTR";
        proxied = false;
        name = "135";
        content = "lagern.sd.ysun.co";
        comment = "AWS - EU Central 2";
      };

      arpa_in_addr_23_161_104_136 = {
        type = "PTR";
        proxied = false;
        name = "136";
        content = "odake.sd.ysun.co";
        comment = "SSDNodes - Tokyo 2";
      };

      arpa_in_addr_23_161_104_137 = {
        type = "PTR";
        proxied = false;
        name = "137";
        content = "walberla.sd.ysun.co";
        comment = "Hetzner - Falkenstein";
      };

      arpa_in_addr_23_161_104_138 = {
        type = "PTR";
        proxied = false;
        name = "138";
        content = "oxide.sd.ysun.co";
        comment = "Oxide Computer - Fremont";
      };

      arpa_in_addr_23_161_104_139 = {
        type = "PTR";
        proxied = false;
        name = "139";
        content = "baldy.sd.ysun.co";
        comment = "NetActuate - Los Angeles";
      };

      arpa_in_addr_23_161_104_140 = {
        type = "PTR";
        proxied = false;
        name = "140";
        content = "cradle.sd.ysun.co";
        comment = "NetActuate - Sydney";
      };

      arpa_in_addr_23_161_104_141 = {
        type = "PTR";
        proxied = false;
        name = "141";
        content = "lantau.sd.ysun.co";
        comment = "NetActuate - Hong Kong";
      };

      arpa_in_addr_23_161_104_142 = {
        type = "PTR";
        proxied = false;
        name = "142";
        content = "roraima.sd.ysun.co";
        comment = "NetActuate - Sao Paulo";
      };

      arpa_in_addr_23_161_104_143 = {
        type = "PTR";
        proxied = false;
        name = "143";
        content = "rysy.sd.ysun.co";
        comment = "NetActuate - Warsaw";
      };
    } // mkPurelyMailRecord
    "104.161.23.in-addr.arpa"
    "arpa_in_addr_23_161_104"
  ;
}
