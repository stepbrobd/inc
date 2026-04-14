{ buildNpmPackage
, fetchzip
}:

buildNpmPackage (finalAttrs: {
  meta.mainProgram = "cf";
  pname = "cf";
  version = "0.0.5";

  src = fetchzip {
    url = "https://registry.npmjs.org/cf/-/cf-${finalAttrs.version}.tgz";
    hash = "sha256-THzx9MeRD1sFyYn8VwRhJzqWCj6b+ASfrVqGhsRa3R4=";
  };

  patchPhase = ''
    runHook prePatch
    cp ${./package-lock.json} package-lock.json
    runHook postPatch
  '';

  npmDepsHash = "sha256-qZHkg0AtojD/1wMVn/fka7o/N9Aq7f6t4h8jSBTR1cQ=";

  dontNpmBuild = true;
})
