{ lib
, buildGoModule
, fetchFromGitHub
, nix-update-script
}:

buildGoModule (finalAttrs: {
  pname = "miruro";
  version = "2026.719.0";

  __structuredAttrs = true;

  __darwinAllowLocalNetworking = true;

  src = fetchFromGitHub {
    owner = "stepbrobd";
    repo = "miruro";
    tag = "v${finalAttrs.version}";
    hash = "sha256-XR0PgXrf6MhPgeAgyKUKX87pcZjUIaf2SczHOIwSxpw=";
  };

  vendorHash = "sha256-Jk0BcgXbTBYBIM5F9my5gLIGweQ8c5uSxSmdu5QAKRE=";

  ldflags = [ "-s" ];

  passthru.updateScript = nix-update-script { };

  passthru.autobump = true;

  meta = {
    description = "Why u here weeb";
    homepage = "https://github.com/stepbrobd/miruro";
    changelog = "https://github.com/stepbrobd/miruro/releases/tag/${finalAttrs.src.tag}";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ stepbrobd ];
    mainProgram = "miruro";
  };
})
