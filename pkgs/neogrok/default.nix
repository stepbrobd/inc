{ stdenvNoCC
, fetchFromGitHub
, makeBinaryWrapper
, nodejs
, yarn-berry
}:

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "neogrok";
  version = "1.2.1";

  src = fetchFromGitHub {
    owner = "isker";
    repo = "neogrok";
    tag = "v${finalAttrs.version}";
    hash = "sha256-xAfXT2QioNKHL25lEAlryeaO3JUfOAIMW2+jaobvukY=";
  };

  # https://github.com/NixOS/nixpkgs/pull/513745
  # https://github.com/NixOS/nixpkgs/issues/513716
  patches = [ ./yarn-4.14.patch ];
  missingHashes = ./missing-hashes.json;
  offlineCache = yarn-berry.fetchYarnBerryDeps {
    inherit nodejs;
    inherit (finalAttrs) src missingHashes patches;
    hash = "sha256-LziXk8kWdeqF4fWjxIR5TDkoYpTj6GQiheGqToCxYnE=";
  };

  nativeBuildInputs = [
    makeBinaryWrapper
    nodejs
    yarn-berry
    yarn-berry.yarnBerryConfigHook
  ];

  buildPhase = ''
    runHook preBuild

    yarn build

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/{bin,lib/neogrok}
    cp -r build node_modules main.js package.json $out/lib/neogrok/

    makeBinaryWrapper ${nodejs}/bin/node $out/bin/neogrok \
      --add-flags $out/lib/neogrok/main.js

    runHook postInstall
  '';

  meta.mainProgram = "neogrok";
})
