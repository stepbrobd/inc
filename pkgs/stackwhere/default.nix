{ lib
, buildGoModule
, fetchFromGitHub
}:

buildGoModule (finalAttrs: {
  pname = "stackwhere";
  version = "0.2.1";

  passthru.autobump = true;

  src = fetchFromGitHub {
    owner = "cilium";
    repo = "stackwhere";
    tag = "v${finalAttrs.version}";
    hash = "sha256-GRoOGQoGxsds3XD6pqFTEni1v1OORlpAiLBMvOWDqj4=";
  };

  vendorHash = "sha256-IrOpxoBXlCM3DdQxqkwVzkfeTkORj6LIfSf1cL4I9Oc=";

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
