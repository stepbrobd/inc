{ lib
, buildGoModule
, fetchFromGitHub
, installShellFiles
, versionCheckHook
, git
}:

buildGoModule (finalAttrs: {
  pname = "miroir";
  version = "2026.920.1";

  __structuredAttrs = true;

  src = fetchFromGitHub {
    owner = "stepbrobd";
    repo = "miroir";
    tag = "v${finalAttrs.version}";
    hash = "sha256-RF3ohHOdj1WeZ641az7lcCJC/r/n6z4ITUZEVcFwIzo=";
  };

  vendorHash = "sha256-MnLkrU8EjgYfj3Pz4a9KZObn60iR56ASWyhCskbWGiE=";

  subPackages = [ "cmd/miroir" ];

  ldflags = [
    "-s"
    "-X main.version=${finalAttrs.version}"
  ];

  nativeBuildInputs = [ installShellFiles ];

  nativeCheckInputs = [ git ];

  postInstall = ''
    for shell in bash zsh fish; do
      installShellCompletion --cmd miroir --$shell <("$out/bin/miroir" completion "$shell")
    done
  '';

  doInstallCheck = true;
  nativeInstallCheckInputs = [ versionCheckHook ];

  passthru.autobump = true;

  meta = {
    description = "Repo manager wannabe?";
    homepage = "https://github.com/stepbrobd/miroir";
    changelog = "https://github.com/stepbrobd/miroir/releases/tag/${finalAttrs.src.tag}";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ stepbrobd ];
    mainProgram = "miroir";
  };
})
