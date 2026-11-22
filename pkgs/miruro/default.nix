{ lib
, buildGoLatestModule
, fetchFromGitHub
}:

buildGoLatestModule (finalAttrs: {
  pname = "miruro";
  version = "2026.1121.0";

  __structuredAttrs = true;
  __darwinAllowLocalNetworking = true;

  src = fetchFromGitHub {
    owner = "stepbrobd";
    repo = "miruro";
    tag = "v${finalAttrs.version}";
    hash = "sha256-HW7YLZvrkA5ItA4WnihkVR0kG+L2pJVOp3EOvkHD0xo=";
  };

  vendorHash = "sha256-syZcXQm+MMmzW5BwWf/bcndrdJGTObyPRlRosTFqRAY=";

  ldflags = [
    "-s"
    "-X main.version=${finalAttrs.version}"
  ];

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
