{ rustPlatform, fetchFromGitHub }:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "jitsi-openid";
  version = "2.1.0";

  src = fetchFromGitHub {
    owner = "MarcelCoding";
    repo = "jitsi-openid";
    tag = "v${finalAttrs.version}";
    hash = "sha256-s/b70kmv8N85Ri26B0k8jsqnvIBMxDo4iOCT1xjmCw0=";
  };

  # use system root
  cargoPatches = [ ./ca.patch ];
  cargoHash = "sha256-CVu1TwprXFxN0/PK1qH3yGG7KJvG+ESXaD/GiM62/IY=";

  passthru.autobump = true;

  meta.mainProgram = "jitsi-openid";
})
