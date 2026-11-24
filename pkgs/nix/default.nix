{ lib
, inputs
, pkgsPrev
}:

let
  src = inputs.nix // { name = "source"; };
in
((pkgsPrev.nixVersions.nixComponents_git.overrideSource src).overrideScope (_: prev: {
  version = "${lib.versions.majorMinor (lib.fileContents "${src}/.version")}pre${lib.substring 0 8 inputs.nix.lastModifiedDate}_${lib.substring 0 8 inputs.nix.rev}";
  # TODO: FIXME: drop after nixpkgs#592556
  nix-expr = prev.nix-expr.overrideAttrs (prevAttrs: {
    nativeBuildInputs = prevAttrs.nativeBuildInputs ++ [ pkgsPrev.buildPackages.re2c ];
  });
})).nix-everything
