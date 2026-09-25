{ lib
, buildGoModule
, fetchFromGitHub
}:

buildGoModule (finalAttrs: {
  pname = "miruro";
  version = "2026.923.0";

  __structuredAttrs = true;
  __darwinAllowLocalNetworking = true;

  src = fetchFromGitHub {
    owner = "stepbrobd";
    repo = "miruro";
    tag = "v${finalAttrs.version}";
    hash = "sha256-zxwfSZFyV0ohTOixk7yvZ5Un/hiO76joue+QFufVGdM=";
  };

  vendorHash = "sha256-wJAloyAqvz4mQ9OzIXfuHsDaXtQRH9STaBqwqKFQh9M=";

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
