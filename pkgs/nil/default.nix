# TODO: drop this after fix?

{ pkgsPrev }:

pkgsPrev.nil.overrideAttrs { doCheck = false; }
