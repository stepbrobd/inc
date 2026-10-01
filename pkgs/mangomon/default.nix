{ lib
, buildGoModule
, fetchFromGitHub
, makeWrapper
, wl-mirror
, wlr-randr
, versionCheckHook
}:

buildGoModule (finalAttrs: {
  pname = "mangomon";
  version = "2026.823.0";

  __structuredAttrs = true;

  src = fetchFromGitHub {
    owner = "stepbrobd";
    repo = "mangomon";
    tag = finalAttrs.version;
    hash = "sha256-q/SwM2YKxWyv0+uMDvtPSS77ZoVYXd2BcPWin1HXEDg=";
  };

  vendorHash = "sha256-eSKuDWtzRxwrRvBKA6z85P/+Lqf7djgqMVu3xv7ttDM=";

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
