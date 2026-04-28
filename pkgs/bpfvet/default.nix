{ lib
, buildGoModule
, fetchFromGitHub
}:

buildGoModule (finalAttrs: {
  pname = "bpfvet";
  version = "0.2.1";

  src = fetchFromGitHub {
    owner = "boratanrikulu";
    repo = "bpfvet";
    tag = "v${finalAttrs.version}";
    hash = "sha256-++vCltHBmy0JPzNjZ7qe1I9eValBcw2V+j9WRZKVAG8=";
  };

  vendorHash = "sha256-hnkmkHUS5QzhnlDXB6CF683aDBTnJC86J4//IBcJLOA=";

  ldflags = [ "-s" ];

  meta = {
    homepage = "https://github.com/boratanrikulu/bpfvet";
    license = lib.licenses.mit;
    mainProgram = "bpfvet";
  };
})
