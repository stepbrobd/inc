{ lib, ... } @ args:

{ ... }:

let
  inherit (lib) map filter attrNames readDir;
in
{
  imports = map
    (f: import ./${f} args)
    (filter
      (f: f != "default.nix")
      (attrNames (readDir ./.)));

  resource.tailscale_tailnet_settings.settings = {
    acls_externally_managed_on = true;
    acls_external_link = "https://github.com/stepbrobd/inc";
    devices_approval_on = true;
    devices_auto_updates_on = true;
    devices_key_duration_days = 180;
    users_approval_on = true;
    users_role_allowed_to_join_external_tailnet = "member";
    posture_identity_collection_on = true;
    # not available in free plan
    # regional_routing_on = true;
    # network_flow_logging_on = true;
  };
}
