{ lib
, buildGoLatestModule
, fetchFromGitHub
, makeWrapper
, wl-mirror
, wlr-randr
, versionCheckHook
}:

buildGoLatestModule (finalAttrs: {
  pname = "mangomon";
  version = "2026.1126.0";

  __structuredAttrs = true;

  src = fetchFromGitHub {
    owner = "stepbrobd";
    repo = "mangomon";
    tag = finalAttrs.version;
    hash = "sha256-QzsSIyK8HmpGeARmY5kbGGyagoSixHKCfII0Njtk69w=";
  };

  vendorHash = "sha256-epGoM+T3XfTYn0THDogJ4rhXLeDsGeEEHHEWdE9X+Aw=";

  ldflags = [
    "-s"
    "-X main.Version=${finalAttrs.version}"
  ];

  nativeBuildInputs = [ makeWrapper ];

  postFixup = ''
    wrapProgram $out/bin/mangomon --prefix PATH : "${lib.makeBinPath [ wl-mirror wlr-randr ]}"
  '';

  doInstallCheck = true;
  nativeInstallCheckInputs = [ versionCheckHook ];
  versionCheckProgramArg = "-version";

  passthru.autobump = true;

  meta = {
    description = "TUI monitor configuration tool for mango wm with visual layout, drag-and-drop, and profile management";
    homepage = "https://github.com/stepbrobd/mangomon";
    changelog = "https://github.com/stepbrobd/mangomon/releases/tag/${finalAttrs.src.tag}";
    license = lib.licenses.asl20;
    maintainers = with lib.maintainers; [ stepbrobd ];
    mainProgram = "mangomon";
    platforms = lib.platforms.linux;
  };
})
