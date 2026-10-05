{ ... }:

let
  resources = [
    { start_address = "2602:f590::"; cidr_length = 36; max_length = 48; }
    { start_address = "23.161.104.0"; cidr_length = 24; max_length = 24; }
    { start_address = "192.104.136.0"; cidr_length = 24; max_length = 24; }
    { start_address = "204.115.20.0"; cidr_length = 23; max_length = 23; }
  ];
in
{
  # roa handles rotate on every update, import by current handle (look up via the arin_roas data source)
  # e.g. `tofu import arin_roa.as10779 <handle>`
  # auto_link is not reported back by arin so freshly imported state holds the schema default (false)
  # the first apply after import flips it and reissues the roa under a new handle
  resource.arin_roa = {
    as10779 = {
      as_number = 10779;
      name = "";
      auto_link = true;
      inherit resources;
    };

    as18932 = {
      as_number = 18932;
      name = "";
      auto_link = true;
      inherit resources;
    };
  };

  # import by customer ASN
  # e.g. `tofu import arin_aspa.as10779 10779`
  resource.arin_aspa = {
    as10779 = {
      customer_as = 10779;
      provider_as_ids = [ 3204 20473 21700 23961 35661 36236 59105 ];
    };

    as18932 = {
      customer_as = 18932;
      provider_as_ids = [ 10779 ];
    };
  };
}
