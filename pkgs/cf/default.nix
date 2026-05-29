{ buildNpmPackage
, fetchzip
}:

buildNpmPackage (finalAttrs: {
  meta.mainProgram = "cf";
  pname = "cf";
  version = "0.0.6";

  src = fetchzip {
    url = "https://registry.npmjs.org/cf/-/cf-${finalAttrs.version}.tgz";
    hash = "sha256-FaBKniLXo6Wjsnr0KVbgnxaWTUKbOckKsbgUlyUHrYg=";
  };

  postPatch = ''
    cp ${./package-lock.json} package-lock.json
  '';

  npmDepsHash = "sha256-qZHkg0AtojD/1wMVn/fka7o/N9Aq7f6t4h8jSBTR1cQ=";

  dontNpmBuild = true;
})
