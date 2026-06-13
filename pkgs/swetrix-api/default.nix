{ lib
, stdenv
, buildNpmPackage
, swetrix
, nodejs_24
, makeWrapper
, autoPatchelfHook
}:

buildNpmPackage (finalAttrs: {
  pname = "swetrix-api";
  inherit (swetrix) version src;

  sourceRoot = "${finalAttrs.src.name}/backend";

  npmDepsHash = "sha256-HamWyCgaNge3GJPAaoPiZJb+WlS44iIUkKbFU3QqWQE=";

  nodejs = nodejs_24;

  nativeBuildInputs = [ makeWrapper autoPatchelfHook ];

  buildInputs = [ stdenv.cc.cc.lib ];

  autoPatchelfIgnoreMissingDeps = [ "libc.musl-x86_64.so.1" ];

  npmFlags = [ "--legacy-peer-deps" ];
  npmInstallFlags = [ "--force" ];

  npmBuildScript = "deploy:community";

  env = {
    SENTRYCLI_SKIP_DOWNLOAD = "1";
    SCARF_ANALYTICS = "false";
  };

  postBuild = ''
    npm prune --omit=dev --legacy-peer-deps
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/swetrix-api
    cp -r dist node_modules migrations package.json $out/share/swetrix-api/

    makeWrapper ${lib.getExe nodejs_24} $out/bin/swetrix-api \
      --add-flags "$out/share/swetrix-api/dist/main.js" \
      --chdir "$out/share/swetrix-api" \
      --set-default NODE_ENV cloud \
      --set-default IS_PRIMARY_NODE true

    makeWrapper ${lib.getExe nodejs_24} $out/bin/swetrix-api-clickhouse-init \
      --add-flags "$out/share/swetrix-api/migrations/clickhouse/initialise_selfhosted.js" \
      --chdir "$out/share/swetrix-api" \
      --set-default NODE_ENV cloud

    runHook postInstall
  '';

  passthru = { inherit (swetrix) tests; };

  meta = {
    homepage = "https://swetrix.com";
    license = lib.licenses.agpl3Only;
    maintainers = with lib.maintainers; [ stepbrobd ];
    mainProgram = "swetrix-api";
    platforms = lib.platforms.linux;
  };
})
