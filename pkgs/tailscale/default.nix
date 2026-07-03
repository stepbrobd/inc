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
  version = "1.101.154";

  src = fetchFromGitHub {
    owner = "tailscale";
    repo = "tailscale";
    rev = "52fdadbf8b9ef5398db4ab9b69ffe1a328c260a6";
    hash = "sha256-8emYx6oWdHaZM/Wc9Z7PWwljfxQcf1qmB+Ra3sR9s5s=";
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
