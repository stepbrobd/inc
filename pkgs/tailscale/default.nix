{ lib
, pkgsPrev
, fetchFromGitHub
, writeShellApplication
, nix-prefetch-github
, coreutils
, git
, gnused
, jq
}:

pkgsPrev.tailscale.overrideAttrs (prev: {
  version = "1.101.145";

  src = fetchFromGitHub {
    owner = "tailscale";
    repo = "tailscale";
    rev = "f96db5e3832b21de1f03e0dc2b5e422b40f73585";
    hash = "sha256-wXPf//z+Jt8/qjPayisZ38Plj8fCrhp9DLoW7C5A/EA=";
  };

  vendorHash = "sha256-UrvJ5fM+Oqgu2pZwhg5AnUcgi8wPwZ8qDwWpXNmKaPk=";

  passthru = (prev.passthru or { }) // {
    autobump = true;
    updateScript = [
      (lib.getExe (writeShellApplication {
        name = "tailscale-updater";
        text = lib.readFile ./update.sh;
        runtimeInputs = [
          coreutils
          git
          gnused
          jq
          nix-prefetch-github
        ];
      }))
    ];
  };
})
