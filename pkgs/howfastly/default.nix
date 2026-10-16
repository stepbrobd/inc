{ lib
, rustPlatform
, fetchFromGitHub
, versionCheckHook
}:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "howfastly";
  version = "2026.1015.0";

  __structuredAttrs = true;

  src = fetchFromGitHub {
    owner = "stepbrobd";
    repo = "howfastly";
    tag = finalAttrs.version;
    hash = "sha256-exfdVbq5ciHGKmf7if+6XvRUU/VX3w4cayki9edG2to=";
  };

  cargoHash = "sha256-jYV8+TPJTpDIIZpjUZdNx+uMsvSntbFxf7ekfsRX2qU=";

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
