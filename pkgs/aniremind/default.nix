{ lib
, writers
, writeShellScript
, python3
, ruff
, ty
, things
}:

let
  pin = ''THINGS = "things"'';
  source = lib.readFile ./main.py;
in
assert lib.hasInfix pin source;
lib.addMetaAttrs
{
  description = "Sync an AniList watchlist into Things 3";
  license = lib.licenses.mit;
  maintainers = with lib.maintainers; [ stepbrobd ];
  platforms = lib.platforms.all;
}
  (writers.makeScriptWriter
  {
    interpreter = lib.getExe python3;
    check = writeShellScript "check" ''
      set -eu
      work=$(mktemp -d)
      trap 'rm -rf "$work"' EXIT
      cp "$1" "$work/main.py"
      export HOME=$work
      ${lib.getExe ruff} format --check "$work/main.py"
      ${lib.getExe ruff} check --no-cache --select E,F,W,I,B,DTZ,TC,RUF,SIM "$work/main.py"
      ${lib.getExe ty} check --error-on-warning "$work/main.py"
    '';
  } "/bin/aniremind"
    (lib.replaceStrings [ pin ] [ ''THINGS = "${lib.getExe things}"'' ] source))
