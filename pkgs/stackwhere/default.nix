{ lib
, buildGoModule
, fetchFromGitHub
}:

buildGoModule (finalAttrs: {
  pname = "stackwhere";
  version = "0.3.1";

  passthru.autobump = true;

  src = fetchFromGitHub {
    owner = "cilium";
    repo = "stackwhere";
    tag = "v${finalAttrs.version}";
    hash = "sha256-d+HZYB/iWGsvan3XIfAvUqMWRlFMG4B+G8beklI3Tr8=";
  };

  vendorHash = "sha256-J2X1uTkRtmdmo8Fxxql6Nu84F6MarWHFTopavUPL+RU=";

  ldflags = [
    "-s"
    "-w"
    "-X=main.version=${finalAttrs.version}"
    "-X=main.commit=${finalAttrs.version}"
    "-X=main.date=1970-01-01T00:00:00Z"
  ];

  meta = {
    description = "A tool for exploring where BPF stack usage comes from";
    homepage = "https://github.com/cilium/stackwhere";
    license = lib.licenses.asl20;
    maintainers = with lib.maintainers; [ stepbrobd ];
    mainProgram = "stackwhere";
  };
})
