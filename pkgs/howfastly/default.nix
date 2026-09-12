{ lib
, rustPlatform
, fetchFromGitHub
, versionCheckHook
}:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "howfastly";
  version = "2026.910.2";

  __structuredAttrs = true;

  src = fetchFromGitHub {
    owner = "stepbrobd";
    repo = "howfastly";
    tag = finalAttrs.version;
    hash = "sha256-9vMuHvkOjmBVAYf8hJhNiyhV3suZg2JR5+lo2AUKaaY=";
  };

  cargoHash = "sha256-ySWGMshf0EInn9hhJMhejLQ/oRTRZBCBBC1i7fEBRAQ=";

  cargoBuildFlags = [ "--package" "howfastly" ];

  useNextest = true;
  cargoTestFlags = [ "--package" "howfastly" ];

  doInstallCheck = true;
  nativeInstallCheckInputs = [ versionCheckHook ];
  versionCheckProgramArg = "--help";

  passthru.autobump = true;

  meta = {
    description = "How fast is your connection to the Fastly network";
    homepage = "https://github.com/stepbrobd/howfastly";
    changelog = "https://github.com/stepbrobd/howfastly/releases/tag/${finalAttrs.src.tag}";
    license = lib.licenses.asl20;
    maintainers = with lib.maintainers; [ stepbrobd ];
    mainProgram = "howfastly";
  };
})
