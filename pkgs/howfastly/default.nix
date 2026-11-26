{ lib
, rustPlatform
, fetchFromGitHub
, aws-lc
, pkg-config
, versionCheckHook
}:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "howfastly";
  version = "2026.1125.0";

  __structuredAttrs = true;

  src = fetchFromGitHub {
    owner = "stepbrobd";
    repo = "howfastly";
    tag = finalAttrs.version;
    hash = "sha256-sAHhAQo9dYJnXCNFhP5rnmCFG7DXPWQweDLcNA/JzOE=";
  };

  cargoHash = "sha256-vlSXYr6KGTbsu2ISRR61JFZ7GP0rAOlci6mHQAAlQ2o=";

  env.AWS_LC_SYS_USE_SYSTEM = true;
  buildInputs = [ aws-lc ];
  nativeBuildInputs = [ pkg-config ];

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
