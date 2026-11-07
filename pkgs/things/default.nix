{ lib
, stdenv
, rustPlatform
, fetchFromGitHub
, aws-lc
, installShellFiles
, pkg-config
, versionCheckHook
, writableTmpDirAsHomeHook
, cacert
, jq
}:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "things";
  version = "2026.1106.0";

  __structuredAttrs = true;

  src = fetchFromGitHub {
    owner = "stepbrobd";
    repo = "things";
    tag = finalAttrs.version;
    hash = "sha256-uk0MljApQz0iIwFS4NvmajkL1Pk4lLkbrHYZjSzRBqQ=";
  };

  cargoHash = "sha256-sstqxcZQRGd8i8tg63vA5ty0wQtMtZvkkVws6chyWL0=";

  env.AWS_LC_SYS_USE_SYSTEM = true;
  buildInputs = [ aws-lc ];

  nativeBuildInputs = [ installShellFiles pkg-config ];

  postInstall = lib.optionalString (stdenv.buildPlatform.canExecute stdenv.hostPlatform) ''
    installShellCompletion --cmd things \
      --bash <($out/bin/things completions bash) \
      --fish <($out/bin/things completions fish) \
      --nushell <($out/bin/things completions nushell) \
      --zsh <($out/bin/things completions zsh)
  '';

  useNextest = true;
  nativeCheckInputs = [ cacert jq writableTmpDirAsHomeHook ];
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
