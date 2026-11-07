{ aws-lc, pkg-config, pkgsPrev }:

# TODO: FIXME: delete this package once nixpkgs' zizmor has aws-lc in buildInputs itself
# nixpkgs#537108 sets AWS_LC_SYS_USE_SYSTEM for every cargo build, tracked in nixpkgs#570938
pkgsPrev.zizmor.overrideAttrs (prev: {
  buildInputs = prev.buildInputs or [ ] ++ [ aws-lc ];
  nativeBuildInputs = prev.nativeBuildInputs or [ ] ++ [ pkg-config ];
})
