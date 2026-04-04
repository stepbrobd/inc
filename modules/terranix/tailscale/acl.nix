{ lib, ... }:

{ ... }:

let
  # derive all tailscale tags from blueprint host tags
  # plus non-blueprint tailscale devices (aperture)
  allHosts = lib.attrValues lib.blueprint.hosts;
  extraTags = [ "aperture" ];
  allTags = lib.unique (lib.concatMap (h: h.tags) allHosts ++ extraTags);
  mkTag = t: "tag:${t}";

  tag = lib.listToAttrs (map (t: { name = t; value = mkTag t; }) allTags);

  autogroup = {
    admin = "autogroup:admin";
    member = "autogroup:member";
    self = "autogroup:self";
    shared = "autogroup:shared";
    internet = "autogroup:internet";
  };

  self = {
    email = "ysun@hey.com";
    username = "ysun";
  };
in
{
  resource.tailscale_acl.acl = {
    overwrite_existing_content = true;
    reset_acl_on_destroy = true;

    acl = lib.toJSON {
      tagOwners = lib.listToAttrs (map
        (t: {
          name = mkTag t;
          value = [ autogroup.admin ];
        })
        allTags);

      grants = [
        # full access for admins and personal devices
        {
          src = [ autogroup.admin tag.laptop ];
          dst = [ "*" ];
          ip = [ "*" ];
        }
        # users within tailnet get to use golink
        {
          src = [ autogroup.member ];
          dst = [ tag.golink ];
          app."tailscale.com/cap/golink" = [{ admin = true; }];
        }
        # users within tailnet get to use
        # their own devices, golink, and exit nodes
        {
          src = [ autogroup.member ];
          dst = [ autogroup.self tag.aperture tag.golink autogroup.internet ];
          ip = [ "*" ];
        }
        # devices shared outside with other ppl
        # can use as exit nodes
        {
          src = [ autogroup.shared ];
          dst = [ autogroup.internet ];
          ip = [ "*" ];
        }
        # infrastructure reach each other and own prefixes but not ssh
        {
          src = with tag; [ server ];
          dst = with tag; [ server ];
          ip = [ "1-21" "23-65535" ];
        }
      ];

      autoApprovers.exitNode = [ tag.server ];

      # ensure each device gets a /32 rule
      # for their v4 address under CGNAT range
      OneCGNATRoute = "";

      nodeAttrs = [
        # test https://github.com/tailscale/tailscale/issues/18758
        # and  https://github.com/tailscale/tailscale/pull/18781
        # on timah, allow upstream router packets and drop cgnat range o.w.
        { target = [ "100.100.101.112" ]; app."ysun.co/tscgnat" = [{ cidr = "100.100.0.0/32"; chain = "both"; verdict = "accept"; } { cidr = "100.64.0.0/10"; chain = "both"; verdict = "drop"; }]; }
        # for other nodes just drop all cgnat range
        # { target = [ "*" ]; app."ysun.co/tscgnat" = [{ cidr = "100.64.0.0/10"; chain = "both"; verdict = "drop"; }]; }
        # see above
        # in tailscale/tailcfg/tailcfg.go:
        # NodeAttrOneCGNATEnable NodeCapability = "one-cgnat?v=false"
        { target = [ "*" ]; attr = [ "one-cgnat?v=false" "funnel" "nextdns:d8664a" ]; }
        { target = [ self.email ]; attr = [ "mullvad" ]; }
        { target = [ "*" ]; ipPool = [ "100.100.101.0/24" ]; }
      ];

      tests =
        let
          nonssh = [
            "100.100.101.0:443"
            "100.100.101.0:179"
          ];
          ssh = [
            "100.100.101.0:22"
          ];
        in
        [
          # laptops get full access
          { src = tag.laptop; proto = "tcp"; accept = nonssh ++ ssh; }
          # servers can reach each other (non-ssh)
          # { src = tag.server; proto = "tcp"; accept = nonssh; }
          # servers cannot ssh to tailnet devices
          { src = tag.server; proto = "tcp"; deny = ssh; }
        ];

      # removed as tailscale ssh does not allow algorithm configuration
      # ssh = [ ];
      # sshTests = [ ];
    };
  };
}
