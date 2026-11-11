{ lib
, rustPlatform
, tailwindcss_4
, pkg-config
, zstd
}:

rustPlatform.buildRustPackage {
  pname = "ysun";
  version = (lib.importTOML ./Cargo.toml).workspace.package.version;

  src = lib.fileset.toSource {
    root = ./.;
    fileset = lib.fileset.unions [
      ./src
      ./generator
      ./build.rs
      ./Cargo.toml
      ./Cargo.lock
      ./license.txt
    ];
  };

  cargoLock.lockFile = ./Cargo.lock;
  cargoBuildFlags = [ "-vv" ];

  nativeBuildInputs = [ pkg-config tailwindcss_4 ];
  buildInputs = [ zstd ];

  env.BUN_JSC_useJIT = "0";

  meta = {
    homepage = "https://ysun.co";
    license = lib.licenses.cc-by-nc-40;
    maintainers = with lib.maintainers; [ stepbrobd ];
    mainProgram = "ysun";
    platforms = lib.platforms.unix;
  };
}
