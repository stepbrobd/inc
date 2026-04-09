{ lib, ... }:

let
  inherit (lib.terranix) forZone mkPersonalSiteRebind mkPurelyMailRecord;
in
{
  resource.cloudflare_dns_record = forZone "0.0.9.5.f.2.0.6.2.ip6.arpa"
    {
      arpa_ip6_2_6_0_2_f_5_9_0_0_apex = mkPersonalSiteRebind { name = "@"; proxied = false; };

      arpa_ip6_2_6_0_2_f_5_9_0_0_0_0_0_0_2_3_1_6_1_0_1_4_0_0_1_7 = {
        type = "PTR";
        proxied = false;
        name = "7.1.0.0.4.0.1.0.1.6.1.0.3.2.0.0.0.0.0.0.0.0.0";
        content = "ysun.co";
        comment = "AS10779 - Anycast";
      };

      arpa_ip6_2_6_0_2_f_5_9_0_0_0_0_0_0_2_3_1_6_1_0_1_4_0_1_2_8 = {
        type = "PTR";
        proxied = false;
        name = "8.2.1.0.4.0.1.0.1.6.1.0.3.2.0.0.0.0.0.0.0.0.0";
        content = "toompea.sd.ysun.co";
        comment = "xTom - Tallinn, Estonia";
      };

      arpa_ip6_2_6_0_2_f_5_9_0_0_0_0_0_0_2_3_1_6_1_0_1_4_0_1_2_9 = {
        type = "PTR";
        proxied = false;
        name = "9.2.1.0.4.0.1.0.1.6.1.0.3.2.0.0.0.0.0.0.0.0.0";
        content = "highline.sd.ysun.co";
        comment = "Neptune - New York";
      };

      arpa_ip6_2_6_0_2_f_5_9_0_0_0_0_0_0_2_3_1_6_1_0_1_4_0_1_3_0 = {
        type = "PTR";
        proxied = false;
        name = "0.3.1.0.4.0.1.0.1.6.1.0.3.2.0.0.0.0.0.0.0.0.0";
        content = "kongo.sd.ysun.co";
        comment = "Vultr - Osaka";
      };

      arpa_ip6_2_6_0_2_f_5_9_0_0_0_0_0_0_2_3_1_6_1_0_1_4_0_1_3_1 = {
        type = "PTR";
        proxied = false;
        name = "1.3.1.0.4.0.1.0.1.6.1.0.3.2.0.0.0.0.0.0.0.0.0";
        content = "timah.sd.ysun.co";
        comment = "Misaka - Singapore";
      };

      arpa_ip6_2_6_0_2_f_5_9_0_0_0_0_0_0_2_3_1_6_1_0_1_4_0_1_3_2 = {
        type = "PTR";
        proxied = false;
        name = "2.3.1.0.4.0.1.0.1.6.1.0.3.2.0.0.0.0.0.0.0.0.0";
        content = "butte.sd.ysun.co";
        comment = "Virtua - Paris";
      };

      arpa_ip6_2_6_0_2_f_5_9_0_0_0_0_0_0_2_3_1_6_1_0_1_4_0_1_3_3 = {
        type = "PTR";
        proxied = false;
        name = "3.3.1.0.4.0.1.0.1.6.1.0.3.2.0.0.0.0.0.0.0.0.0";
        content = "isere.sd.ysun.co";
        comment = "Raspberry Pi 5B - Grenoble";
      };

      arpa_ip6_2_6_0_2_f_5_9_0_0_0_0_0_0_2_3_1_6_1_0_1_4_0_1_3_4 = {
        type = "PTR";
        proxied = false;
        name = "4.3.1.0.4.0.1.0.1.6.1.0.3.2.0.0.0.0.0.0.0.0.0";
        content = "halti.sd.ysun.co";
        comment = "Garnix - Hosting";
      };

      arpa_ip6_2_6_0_2_f_5_9_0_0_0_0_0_0_2_3_1_6_1_0_1_4_0_1_3_5 = {
        type = "PTR";
        proxied = false;
        name = "5.3.1.0.4.0.1.0.1.6.1.0.3.2.0.0.0.0.0.0.0.0.0";
        content = "lagern.sd.ysun.co";
        comment = "AWS - EU Central 2";
      };

      arpa_ip6_2_6_0_2_f_5_9_0_0_0_0_0_0_2_3_1_6_1_0_1_4_0_1_3_6 = {
        type = "PTR";
        proxied = false;
        name = "6.3.1.0.4.0.1.0.1.6.1.0.3.2.0.0.0.0.0.0.0.0.0";
        content = "odake.sd.ysun.co";
        comment = "SSDNodes - Tokyo 2";
      };

      arpa_ip6_2_6_0_2_f_5_9_0_0_0_0_0_0_2_3_1_6_1_0_1_4_0_1_3_7 = {
        type = "PTR";
        proxied = false;
        name = "7.3.1.0.4.0.1.0.1.6.1.0.3.2.0.0.0.0.0.0.0.0.0";
        content = "walberla.sd.ysun.co";
        comment = "Hetzner - Falkenstein";
      };

      arpa_ip6_2_6_0_2_f_5_9_0_0_0_0_0_0_2_3_1_6_1_0_1_4_0_1_3_8 = {
        type = "PTR";
        proxied = false;
        name = "8.3.1.0.4.0.1.0.1.6.1.0.3.2.0.0.0.0.0.0.0.0.0";
        content = "oxide.sd.ysun.co";
        comment = "Oxide Computer - Fremont";
      };

      arpa_ip6_2_6_0_2_f_5_9_0_0_0_0_0_0_2_3_1_6_1_0_1_4_0_1_3_9 = {
        type = "PTR";
        proxied = false;
        name = "9.3.1.0.4.0.1.0.1.6.1.0.3.2.0.0.0.0.0.0.0.0.0";
        content = "baldy.sd.ysun.co";
        comment = "NetActuate - Los Angeles";
      };

      arpa_ip6_2_6_0_2_f_5_9_0_0_0_0_0_0_2_3_1_6_1_0_1_4_0_1_4_0 = {
        type = "PTR";
        proxied = false;
        name = "0.4.1.0.4.0.1.0.1.6.1.0.3.2.0.0.0.0.0.0.0.0.0";
        content = "cradle.sd.ysun.co";
        comment = "NetActuate - Sydney";
      };

      arpa_ip6_2_6_0_2_f_5_9_0_0_0_0_0_0_2_3_1_6_1_0_1_4_0_1_4_1 = {
        type = "PTR";
        proxied = false;
        name = "1.4.1.0.4.0.1.0.1.6.1.0.3.2.0.0.0.0.0.0.0.0.0";
        content = "lantau.sd.ysun.co";
        comment = "NetActuate - Hong Kong";
      };

      arpa_ip6_2_6_0_2_f_5_9_0_0_0_0_0_0_2_3_1_6_1_0_1_4_0_1_4_2 = {
        type = "PTR";
        proxied = false;
        name = "2.4.1.0.4.0.1.0.1.6.1.0.3.2.0.0.0.0.0.0.0.0.0";
        content = "roraima.sd.ysun.co";
        comment = "NetActuate - Sao Paulo";
      };

      arpa_ip6_2_6_0_2_f_5_9_0_0_0_0_0_0_2_3_1_6_1_0_1_4_0_1_4_3 = {
        type = "PTR";
        proxied = false;
        name = "3.4.1.0.4.0.1.0.1.6.1.0.3.2.0.0.0.0.0.0.0.0.0";
        content = "rysy.sd.ysun.co";
        comment = "NetActuate - Warsaw";
      };
    } // mkPurelyMailRecord
    "0.0.9.5.f.2.0.6.2.ip6.arpa"
    "arpa_ip6_2_6_0_2_f_5_9_0_0"
  ;
}
