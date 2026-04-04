{ lib, ... }:

{ ... }:

let
  inherit (lib.terranix) mkDevices tfRef;
  bp = lib.blueprint.hosts;

  # all devices in tailnet
  devices = [
    "butte"
    "halti"
    "highline"
    "isere"
    "kongo"
    "lagern"
    "odake"
    "oxide"
    "timah"
    "toompea"
    "walberla"
    # aperture
    "aperture"
    # golink
    "go"
    # untagged
    "framework"
    "iphone"
    "macbook"
    "tv"
    "vision"
    "xps"
  ];

  # devices that have blueprint entries get their tags synced
  blueprintDevices = lib.filter (d: bp ? ${d}) devices;

  mkDeviceTags = d: tags: {
    name = d;
    value = {
      device_id = tfRef "data.tailscale_device.${d}.id";
      tags = map (t: "tag:${t}") tags;
    };
  };

  # non-blueprint tailscale devices with specific tags
  extraDeviceTags = {
    aperture = [ "aperture" ];
    go = [ "golink" ];
  };
in
{
  data.tailscale_devices.all = { };

  data.tailscale_device = mkDevices devices;

  resource.tailscale_device_tags =
    lib.listToAttrs (map (d: mkDeviceTags d bp.${d}.tags) blueprintDevices)
    // lib.mapAttrs
      (d: tags: {
        device_id = tfRef "data.tailscale_device.${d}.id";
        tags = map (t: "tag:${t}") tags;
      })
      extraDeviceTags;
}
