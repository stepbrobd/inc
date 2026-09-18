{ lib
, rustPlatform
, fetchFromGitHub
, versionCheckHook
, writableTmpDirAsHomeHook
, jq
}:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "things";
  version = "2026.918.0";

  __structuredAttrs = true;

  src = fetchFromGitHub {
    owner = "stepbrobd";
    repo = "things";
    tag = finalAttrs.version;
    hash = "sha256-zJ0WiNmbRJTqW/TsL8hNepKjh23o8Ectrd4Evp2jBO8=";
  };

  cargoHash = "sha256-db0BI972jfXR+PGdNznyuN7fqFQwN0UR40IPPhiuIao=";

  useNextest = true;
  nativeCheckInputs = [ jq writableTmpDirAsHomeHook ];
  preCheck = "patchShebangs tests/cli/run.sh";

  doInstallCheck = true;
  nativeInstallCheckInputs = [ versionCheckHook ];
  versionCheckProgramArg = "--help";

  passthru.autobump = true;

  meta = {
    description = "Command-line client for Things 3 using the Things Cloud API";
    homepage = "https://github.com/stepbrobd/things";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ stepbrobd ];
    mainProgram = "things";
  };
})
