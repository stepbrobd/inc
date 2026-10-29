{ lib
, rustPlatform
}:

rustPlatform.buildRustPackage {
  pname = "mcp";
  version = (lib.importTOML ./Cargo.toml).package.version;

  src = lib.fileset.toSource {
    root = ./.;
    fileset = lib.fileset.unions [
      ./src
      ./Cargo.toml
      ./Cargo.lock
    ];
  };

  cargoLock.lockFile = ./Cargo.lock;

  meta = {
    mainProgram = "mcp";
    platforms = lib.platforms.unix;
  };
}
