{ lib
, rustPlatform
, fetchFromGitHub
, pkg-config
, nix-update-script
}:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "howfastly";
  version = "2026.719.0";
  __structuredAttrs = true;

  src = fetchFromGitHub {
    owner = "stepbrobd";
    repo = "howfastly";
    tag = finalAttrs.version;
    hash = "sha256-VmzUrdrgTMdshubvRmh54NRqvsI0kr4GMy6ac9TwmNE=";
  };

  cargoHash = "sha256-uH3CCxczoVbjHgubnzWEX2tBFtH1MgZLWEiwIJK1EAQ=";

  nativeBuildInputs = [ pkg-config ];

  cargoBuildFlags = [ "--package" "cli" ];

  doCheck = false;

  passthru.updateScript = nix-update-script { };

  passthru.autobump = true;

  meta = {
    description = "How fast is your connection to the Fastly network";
    homepage = "https://github.com/stepbrobd/howfastly";
    changelog = "https://github.com/stepbrobd/howfastly/releases/tag/${finalAttrs.src.tag}";
    license = lib.licenses.asl20;
    maintainers = with lib.maintainers; [ stepbrobd ];
    mainProgram = "howfastly";
  };
})
