{ lib
, stdenv
, rustPlatform
, fetchFromGitHub
, installShellFiles
, versionCheckHook
, writableTmpDirAsHomeHook
, jq
}:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "things";
  version = "2026.924.1";

  __structuredAttrs = true;

  src = fetchFromGitHub {
    owner = "stepbrobd";
    repo = "things";
    tag = finalAttrs.version;
    hash = "sha256-6pY0hACm9WnM8FEl3uwqy6DD8GJu3eQ4UBTcLUPNtDQ=";
  };

  cargoHash = "sha256-5LRXxCh0wxFfeAT3PQmvYLjTODNs2xGR8avA7rqQ/rQ=";

  nativeBuildInputs = [ installShellFiles ];

  postInstall = lib.optionalString (stdenv.buildPlatform.canExecute stdenv.hostPlatform) ''
    installShellCompletion --cmd things \
      --bash <($out/bin/things completions bash) \
      --fish <($out/bin/things completions fish) \
      --nushell <($out/bin/things completions nushell) \
      --zsh <($out/bin/things completions zsh)
  '';

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
