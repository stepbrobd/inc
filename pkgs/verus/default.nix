{ lib
, callPackage
, stdenv
, apple-sdk
, makeRustPlatform
, rust-bin
, fetchFromGitHub
, git
, makeWrapper
, zlib
}:

let
  pname = "verus";
  version = "release/rolling/0.2026.04.03.21dfcd2";
  src = fetchFromGitHub {
    leaveDotGit = true;
    owner = "verus-lang";
    repo = "verus";
    tag = version;
    hash = "sha256-3FDWGEO5sdYWCg1C0e5wHoXxtK3P2jJkJsQvsPk+QRo=";
  };

  rustToolchain = rust-bin.fromRustupToolchainFile "${src}/rust-toolchain.toml";
  rustPlatform = makeRustPlatform {
    cargo = rustToolchain;
    rustc = rustToolchain;
  };

  rustup = callPackage ./rustup.nix {
    toolchainName = "${rustToolchain.version}-${{
      x86_64-linux = "x86_64-unknown-linux-gnu";
      aarch64-linux = "aarch64-unknown-linux-gnu";
      x86_64-darwin = "x86_64-apple-darwin";
      aarch64-darwin = "aarch64-apple-darwin";
    }.${stdenv.hostPlatform.system}}";
  };
  vargo = callPackage ./vargo.nix { };
  z3 = callPackage ./z3.nix { };
in
rustPlatform.buildRustPackage (finalAttrs: {
  inherit pname version src;

  sourceRoot = "source/source";

  cargoLock = {
    lockFile = "${src}/source/Cargo.lock";
    outputHashes = {
      "getopts-0.2.21" = "sha256-N/QJvyOmLoU5TabrXi8i0a5s23ldeupmBUzP8waVOiU=";
    };
  };

  RUSTC_BOOTSTRAP = 1;
  VERUS_Z3_PATH = lib.getExe z3;

  buildInputs = [ zlib ] ++ lib.optional stdenv.hostPlatform.isDarwin apple-sdk;

  nativeBuildInputs = [
    makeWrapper
    git
    rustup
    vargo
    z3
  ];

  buildPhase = ''
    runHook preBuild

    vargo build --release

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib $out/bin
    cp -r target-verus/release $out/lib/verus-root

    wrapProgram $out/lib/verus-root/verus \
      --prefix PATH : ${lib.makeBinPath [ rustup ]}

    ln -s ../lib/verus-root/verus $out/bin
    ln -s ../lib/verus-root/cargo-verus $out/bin

    runHook postInstall
  '';

  preFixup = ""
    + lib.optionalString stdenv.hostPlatform.isDarwin ''
    install_name_tool -add_rpath ${lib.makeLibraryPath [ rustPlatform.rust.rustc ]}  $out/lib/verus-root/rust_verify
  ''
    + lib.optionalString stdenv.hostPlatform.isLinux ''
    patchelf --set-rpath ${lib.makeLibraryPath [ rustPlatform.rust.rustc ]} $out/lib/verus-root/rust_verify
  '';

  doCheck = false;

  passthru = {
    inherit
      rustToolchain
      rustPlatform
      vargo
      z3
      ;
  };

  meta = {
    # broken = true;
    mainProgram = "verus";
  };
})
