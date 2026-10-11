{ lib
, inputs
, pkgsPrev
}:

let
  src = inputs.nix // { name = "source"; };
in
((pkgsPrev.nixVersions.nixComponents_git.overrideSource src).overrideScope (_: _: {
  version = "${lib.fileContents "${src}/.version"}pre${lib.substring 0 8 inputs.nix.lastModifiedDate}_${inputs.nix.shortRev}";
})).nix-everything
