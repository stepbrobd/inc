{ lib
, buildGoModule
, fetchFromGitHub
}:

buildGoModule (finalAttrs: {
  pname = "nirimon";
  version = "0-unstable-2026-05-11";

  src = fetchFromGitHub {
    owner = "stepbrobd";
    repo = "nirimon";
    rev = "d0734792703af36f0f50f22a1d8f1f5969dc68da";
    hash = "sha256-w/Snp3Mg+FAXRFJUEz/npmy+16jcfkLBkS8JFbTsmQ4=";
  };

  vendorHash = "sha256-n4RZxpsrlSUD3B/GLVoM2CPckvDkbyaMyg6h4QNbuH0=";

  ldflags = [ "-s" ];

  meta = {
    description = "Tui monitor configuration tool for niri with visual layout, drag-and-drop, and profile management";
    homepage = "https://github.com/stepbrobd/nirimon";
    license = lib.licenses.asl20;
    platforms = lib.platforms.linux;
    maintainers = with lib.maintainers; [ stepbrobd ];
    mainProgram = "nirimon";
  };
})
