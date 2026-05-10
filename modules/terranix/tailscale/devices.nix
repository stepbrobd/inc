{ lib, ... }:

{ ... }:

let
  inherit (lib.terranix) mkDevices;

  devices = [
    "baldy"
    "butte"
    "cradle"
    "halti"
    "highline"
    "isere"
    "kongo"
    "lagern"
    "lantau"
    "odake"
    "oxide"
    "roraima"
    "rysy"
    "timah"
    "toompea"
    "walberla"

    "framework"
    "iphone"
    "macbook"
    "vision"
    "xps"
  ];
in
{
  data.tailscale_devices.all = { };

  data.tailscale_device = mkDevices devices;
}
