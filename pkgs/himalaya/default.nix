{ libgit2, pkgsPrev, sqlite }:

(pkgsPrev.himalaya.override { buildFeatures = [ "native-tls" ]; }).overrideAttrs (prev: {
  # TODO: FIXME: drop the overrideAttrs with the libgit2 and sqlite args once nixpkgs#584922 is in inc's nixpkgs
  # nixpkgs#537108 makes libgit2-sys and libsqlite3-sys link the system libraries
  buildInputs = prev.buildInputs or [ ] ++ [ libgit2 sqlite ];
})
