{ pkgs
, pkgsPrev ? pkgs
, # `pkgsPrev` only provided in overlays
}:

pkgsPrev.jitsi-meet.overrideAttrs {
  patches = pkgs.lib.singleton ./plausible.patch;
}
