{ lib
, buildGoModule
, fetchFromGitHub
}:

buildGoModule (finalAttrs: {
  pname = "stackwhere";
  version = "0.2.0";

  src = fetchFromGitHub {
    owner = "cilium";
    repo = "stackwhere";
    tag = "v${finalAttrs.version}";
    hash = "sha256-0Q6INMQPhLCm2NW0Bxnj/VKgjmQVch6/fLIRzVj5xxQ=";
  };

  vendorHash = "sha256-BiToZ2LcJsd/x9qf9sJ4WQ4Wgz4v3ldXfMZXnsI9RpM=";

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
