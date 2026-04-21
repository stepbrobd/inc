{ lib
, stdenv
, fetchzip
, autoPatchelfHook
, fixDarwinDylibNames
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "z3";
  version = "4.12.5";

  src = fetchzip {
    aarch64-darwin = {
      url = "https://github.com/z3prover/z3/releases/download/z3-${finalAttrs.version}/z3-${finalAttrs.version}-arm64-osx-11.0.zip";
      hash = "sha256-Dkrqjn56UIZcNYKDFZkn2QVLWou4Vf0NjKIITSsweeU=";
    };
    aarch64-linux = {
      url = "https://github.com/z3prover/z3/releases/download/z3-${finalAttrs.version}/z3-${finalAttrs.version}-arm64-glibc-2.35.zip";
      hash = "sha256-+kPQBHmKI7HyCp7oSFNAm321hXwyonSSVXTTvo4tVSA=";
    };
    x86_64-linux = {
      url = "https://github.com/z3prover/z3/releases/download/z3-${finalAttrs.version}/z3-${finalAttrs.version}-x64-glibc-2.31.zip";
      hash = "sha256-kHWanLxL180OPiDSvrxXjgyd/sKFHVgX5/SFfL+pJJs=";
    };
  }.${stdenv.hostPlatform.system};

  dontConfigure = true;
  dontBuild = true;
  dontStrip = true;

  nativeBuildInputs = [ ]
    ++ lib.optional stdenv.isDarwin fixDarwinDylibNames
    ++ lib.optionals stdenv.isLinux [ autoPatchelfHook stdenv.cc.cc.lib ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin
    cp bin/z3 $out/bin/z3

    runHook postInstall
  '';

  meta.mainProgram = "z3";
})
