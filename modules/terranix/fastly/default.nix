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
}
