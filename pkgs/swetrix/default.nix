{ inputs
, lib
, pkgsFinal
, buildNpmPackage
, fetchFromGitHub
, nodejs_24
, makeWrapper
}:

buildNpmPackage (finalAttrs: {
  pname = "swetrix";
  version = "5.2.2";

  src = fetchFromGitHub {
    owner = "Swetrix";
    repo = "swetrix";
    tag = "v${finalAttrs.version}";
    hash = "sha256-JwsjX/JixrS75xwM/6FcBxzEl3Wd2xo6KbKEYTLGfJw=";
  };

  sourceRoot = "${finalAttrs.src.name}/web";

  npmDepsHash = "sha256-gp0zG7/j9uaELNz6u5uuQGZBYcZIcZ4R044SDhvGgrA=";

  nodejs = nodejs_24;

  nativeBuildInputs = [ makeWrapper ];

  npmFlags = [ "--legacy-peer-deps" ];

  preBuild = ''
    export NODE_ENV=production
    export __SELFHOSTED=true
  '';

  postBuild = ''
    npm prune --omit=dev --legacy-peer-deps
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/swetrix
    cp -r build public package.json node_modules $out/share/swetrix/

    makeWrapper ${lib.getExe nodejs_24} $out/bin/swetrix \
      --add-flags "$out/share/swetrix/node_modules/@react-router/serve/dist/cli.js" \
      --add-flags "$out/share/swetrix/build/server/index.js" \
      --chdir "$out/share/swetrix" \
      --set-default NODE_ENV production \
      --set __SELFHOSTED true \
      --set-default PORT 3000

    runHook postInstall
  '';

  passthru.tests.swetrix = pkgsFinal.callPackage ./test.nix { inherit inputs; pkgs = pkgsFinal; };

  meta = {
    homepage = "https://swetrix.com";
    license = lib.licenses.agpl3Only;
    maintainers = with lib.maintainers; [ stepbrobd ];
    mainProgram = "swetrix";
    platforms = lib.platforms.linux;
  };
})
