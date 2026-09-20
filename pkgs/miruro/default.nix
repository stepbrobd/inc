{ lib
, buildGoModule
, fetchFromGitHub
}:

buildGoModule (finalAttrs: {
  pname = "miruro";
  version = "2026.920.1";

  __structuredAttrs = true;
  __darwinAllowLocalNetworking = true;

  src = fetchFromGitHub {
    owner = "stepbrobd";
    repo = "miruro";
    tag = "v${finalAttrs.version}";
    hash = "sha256-Pfy0FKVrfQlHXz1UTY4ltkIHEM57ACFOw4ko7mPQXw0=";
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
