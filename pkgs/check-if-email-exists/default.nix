{ rustPlatform
, fetchFromGitHub
, openssl
, pkg-config
}:
rustPlatform.buildRustPackage (finalAttrs: {
  pname = "check-if-email-exists";
  version = "0.11.7";

  passthru.autobump = true;

  src = fetchFromGitHub {
    owner = "reacherhq";
    repo = "check-if-email-exists";
    tag = "v${finalAttrs.version}";
    hash = "sha256-KRnSTufgpmT6Yo+7NcaRARjtXOCwvbcXXX4or8YTmjo=";
  };

  cargoHash = "sha256-syuwY4qpnvWTXDZ6onnpFSmiEs1GCttSDtR5+vzuUDY=";

  env.OPENSSL_NO_VENDOR = 1;

  nativeBuildInputs = [
    pkg-config
  ];

  buildInputs = [
    openssl
  ];

  checkFlags = [
    "--skip=smtp::tests::should_timeout"
    "--skip=tests::test_input_foo_bar_baz"
  ];

  meta.mainProgram = "check_if_email_exists";
})
