{ ... }:

let
  descriptions = [ "https://stepbrobd.com" ];
  mbrs_by_ref = [ "MNT-STEPB" ];
in
{
  # arin_irr_route route/route6 objects are auto-linked from the roas and maintained by arin

  resource.arin_irr_aut_num = {
    as10779 = {
      as_number = 10779;
      as_name = "STEPBROBD";
      inherit descriptions;
      mp_imports = [ "afi any from AS10779:AS-UPSTREAM accept ANY" ];
      mp_exports = [ "afi any to AS10779:AS-UPSTREAM announce AS10779:AS-TRANSIT" ];
      mp_defaults = [ "to AS10779:AS-TRANSIT networks ANY" ];
    };

    as18932 = {
      as_number = 18932;
      as_name = "STEPBROBD";
      inherit descriptions;
      mp_imports = [ "afi any from AS18932:AS-UPSTREAM accept ANY" ];
      mp_exports = [ "afi any to AS18932:AS-UPSTREAM announce AS18932:AS-TRANSIT" ];
      mp_defaults = [ "to AS18932:AS-TRANSIT networks ANY" ];
    };
  };

  resource.arin_irr_as_set = {
    as10779_stepbrobd = {
      name = "AS10779:AS-STEPBROBD";
      inherit descriptions mbrs_by_ref;
      members = [ "AS10779:AS-OWN" ];
    };

    as10779_own = {
      name = "AS10779:AS-OWN";
      inherit descriptions mbrs_by_ref;
      members = [ "AS10779" "AS18932" ];
    };

    as10779_transit = {
      name = "AS10779:AS-TRANSIT";
      inherit descriptions mbrs_by_ref;
      members = [ "AS10779:AS-OWN" "AS209297" ];
    };

    as10779_upstream = {
      name = "AS10779:AS-UPSTREAM";
      inherit descriptions mbrs_by_ref;
      members = [ "AS3204" "AS20473" "AS21700" "AS23961" "AS35661" "AS36236" "AS59105" ];
    };

    as18932_stepbrobd = {
      name = "AS18932:AS-STEPBROBD";
      inherit descriptions mbrs_by_ref;
      members = [ "AS18932:AS-OWN" ];
    };

    as18932_own = {
      name = "AS18932:AS-OWN";
      inherit descriptions mbrs_by_ref;
      members = [ "AS10779" "AS18932" ];
    };

    as18932_transit = {
      name = "AS18932:AS-TRANSIT";
      inherit descriptions mbrs_by_ref;
      members = [ "AS18932:AS-OWN" ];
    };

    as18932_upstream = {
      name = "AS18932:AS-UPSTREAM";
      inherit descriptions mbrs_by_ref;
      members = [ "AS10779" ];
    };
  };

  # member strings must match arin stored form exactly
  # arin keeps the uppercase and provider does not canonicalize
  resource.arin_irr_route_set.rs_stepbrobd = {
    name = "RS-STEPBROBD";
    inherit descriptions mbrs_by_ref;
    mp_members = [ "23.161.104.0/24" "44.32.189.0/24" "192.104.136.0/24" "204.115.20.0/23" "2602:F590::/36" ];
  };
}
