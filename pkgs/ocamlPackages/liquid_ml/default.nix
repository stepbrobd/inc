{ buildDunePackage
, fetchFromGitHub
, alcotest
, base
, core
, liquid_interpreter
, liquid_parser
, liquid_std
, liquid_syntax
, re2
, stdio
}:

buildDunePackage (finalAttrs: {
  pname = "liquid_ml";
  version = "0.1.4";

  src = fetchFromGitHub {
    owner = "benfaerber";
    repo = "liquid-ml";
    tag = finalAttrs.version;
    hash = "sha256-yppcmAU9ZxV8ZUI1afzGE29HPQ5V/aQQ7k++bY8hx7g=";
  };

  env.DUNE_CACHE = "disabled";

  propagatedBuildInputs = [
    base
    core
    liquid_interpreter
    liquid_parser
    liquid_std
    liquid_syntax
    re2
    stdio
  ];

  doCheck = true;

  checkInputs = [
    alcotest
  ];
})
