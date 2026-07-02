{ lib, ... }:

{ ... }:

{
  resource.tailscale_acl.acl = {
    overwrite_existing_content = true;
    reset_acl_on_destroy = true;

    acl = lib.toJSON {
      grants = [{ src = [ "*" ]; dst = [ "*" ]; ip = [ "*" ]; }];

      # cannot create oauth clients without tags
      # access is already covered by *:*
      tagOwners."tag:ci" = [ "autogroup:admin" ];

      autoApprovers.exitNode = [ "autogroup:member" ];

      # disable-linux-cgnat-drop-rule:
      # https://github.com/tailscale/tailscale/issues/18758
      # https://github.com/tailscale/tailscale/pull/18781
      # https://github.com/tailscale/tailscale/pull/19315
      nodeAttrs = [
        { target = [ "*" ]; ipPool = [ "100.100.101.0/24" ]; }
        { target = [ "*" ]; attr = [ "disable-linux-cgnat-drop-rule" "funnel" "nextdns:d8664a" ]; }
        { target = [ "ysun@hey.com" ]; attr = [ "mullvad" ]; }
      ];
    };
  };
}
