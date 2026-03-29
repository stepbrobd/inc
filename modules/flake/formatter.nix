{
  perSystem = { lib, pkgs, ... }: {
    formatter = pkgs.writeShellScriptBin "formatter" ''
      shopt -s globstar
      set -eoux pipefail

      root="$PWD"
      while [[ ! -f "$root/.git/index" ]]; do
        if [[ "$root" == "/" ]]; then
          exit 1
        fi
        root="$(dirname "$root")"
      done
      pushd "$root" > /dev/null

      ${lib.getExe pkgs.actionlint} -color
      ${lib.getExe pkgs.deno} fmt .
      ${lib.getExe pkgs.gitleaks} git --no-banner --pre-commit --staged
      ${lib.getExe pkgs.nixpkgs-fmt} .
      ${lib.getExe pkgs.taplo} format **/*.toml

      popd
    '';
  };
}
