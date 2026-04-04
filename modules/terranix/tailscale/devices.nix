{ lib, ... }:

{ ... }:

let
  inherit (lib.terranix) mkDevices;
in
{
  data.tailscale_devices.all = { };

  data.tailscale_device = mkDevices [
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
}
