{ lib
, stdenv
, rustPlatform
, installShellFiles
}:

rustPlatform.buildRustPackage {
  pname = "aniremind";
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

  nativeBuildInputs = [ installShellFiles ];

  postInstall = lib.optionalString (stdenv.buildPlatform.canExecute stdenv.hostPlatform) ''
    installShellCompletion --cmd aniremind \
      --bash <($out/bin/aniremind --completions bash) \
      --fish <($out/bin/aniremind --completions fish) \
      --nushell <($out/bin/aniremind --completions nushell) \
      --zsh <($out/bin/aniremind --completions zsh)
  '';

  meta = {
    description = "Sync an AniList watchlist into Things 3";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ stepbrobd ];
    mainProgram = "aniremind";
    platforms = lib.platforms.all;
  };
}
