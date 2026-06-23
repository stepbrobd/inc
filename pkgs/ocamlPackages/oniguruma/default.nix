{ buildDunePackage
, fetchzip
, dune-configurator
, pkgs
}:

buildDunePackage (finalAttrs: {
  pname = "oniguruma";
  version = "0.2.0";

  passthru.autobump = true;

  src = fetchzip {
    url = "https://github.com/alan-j-hu/ocaml-oniguruma/releases/download/${finalAttrs.version}/oniguruma-${finalAttrs.version}.tbz";
    hash = "sha256-syWTGBuQOrI6dLyMOO8TF2v6dE1/Sr39GI0vl2OXdhs=";
  };

  env.DUNE_CACHE = "disabled";

  buildInputs = [ dune-configurator ];

  propagatedBuildInputs = [
    pkgs.oniguruma
  ];

  doCheck = true;
})
