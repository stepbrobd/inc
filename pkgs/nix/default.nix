{ lib
, inputs
, pkgsPrev
}:

let
  src = inputs.nix // { name = "source"; };
in
((pkgsPrev.nixVersions.nixComponents_git.overrideSource src).overrideScope (_: prev: {
  version = "${lib.versions.majorMinor (lib.fileContents "${src}/.version")}pre${lib.substring 0 8 inputs.nix.lastModifiedDate}_${lib.substring 0 8 inputs.nix.rev}";
  # TODO: FIXME: https://github.com/NixOS/nixpkgs/pull/576476
  nix-util-tests = prev.nix-util-tests.overrideAttrs (prevAttrs: {
    excludedTestPatterns = prevAttrs.excludedTestPatterns ++ [ "Root*" ];
  });
})).nix-everything
