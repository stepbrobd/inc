{ lib
, buildGoModule
, fetchFromGitHub
}:

buildGoModule (finalAttrs: {
  pname = "nirimon";
  version = "2026.519.0";

  src = fetchFromGitHub {
    owner = "stepbrobd";
    repo = "nirimon";
    tag = finalAttrs.version;
    hash = "sha256-1bKC1QkWorzfg87xwuGgkIOlLWCj0cotYhpZXYSSm9w=";
  };

  vendorHash = "sha256-/Yihk4SM5s1F7KKZsUnG1ZQgHDPKxi/GPL8blPDgUkk=";

  ldflags = [
    "-s"
    "-w"
    "-X main.Version=${finalAttrs.version}"
  ];

  meta = {
    description = "tui monitor configuration tool for niri with visual layout, drag-and-drop, and profile management";
    homepage = "https://github.com/stepbrobd/nirimon";
    license = lib.licenses.asl20;
    mainProgram = "nirimon";
    maintainers = with lib.maintainers; [ stepbrobd ];
    platforms = lib.platforms.linux;
  };
})
