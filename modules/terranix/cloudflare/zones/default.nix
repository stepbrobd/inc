{ lib, ... } @ args:

{ ... }:

let
  inherit (lib) map filter flatten attrNames readDir deepMergeAttrsList;
  inherit (lib.terranix) mkZoneSettingResources;

  zones = filter (f: f != "default.nix") (attrNames (readDir ./.));
in
{
  imports = flatten (map
    (f: [
      (import ./${f}/dns.nix args)
      (import ./${f}/zone.nix args)
    ])
    zones);

  # common zone settings applied unconditionally
  resource.cloudflare_zone_setting = deepMergeAttrsList (map mkZoneSettingResources zones);
}
