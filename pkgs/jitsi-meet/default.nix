{ lib, pkgsPrev }:

pkgsPrev.jitsi-meet.overrideAttrs {
  patches = lib.singleton ./plausible.patch;
  meta.insecure = false;
}
