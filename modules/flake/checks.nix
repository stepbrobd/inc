{ lib, ... }:

let
  inherit (lib) mapAttrs' nameValuePair;

  checksFor = name: checks: mapAttrs'
    (n: v: nameValuePair (name + "." + n) v)
    checks;
in
{
  perSystem = { self', ... }: {
    checks = checksFor "packages" self'.packages;
  };
}
