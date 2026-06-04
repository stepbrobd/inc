{ lib, ... }:

{
  perSystem =
    { pkgs, ... }: {
      legacyPackages = lib.localPackagesFrom {
        dir = ../../pkgs;
        scope = pkgs;
      };
    };
}
