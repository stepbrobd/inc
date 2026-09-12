{ lib
, buildGoModule
, fetchFromGitHub
, tree-sitter-grammars
}:

buildGoModule {
  pname = "typenix";
  version = "0-unstable-2026-03-12";

  __structuredAttrs = true;

  env.CGO_ENABLED = 1;

  src = fetchFromGitHub {
    owner = "ryanrasti";
    repo = "typenix";
    rev = "13550ee05461121a74a6467aefc479a62026cdfc";
    hash = "sha256-lLnCbe+m2R6ONA+EYLu8bC8slMjC28wnO0Qsuic89Ww=";
  };

  vendorHash = "sha256-dBeHvSWuiCoAMezWx0VXstrATvmTILv183o2jWnc058=";

  subPackages = [ "cmd/tsgo" ];

  ldflags = [ "-s" ];

  preBuild = ''
    ln -sfn ${tree-sitter-grammars.tree-sitter-nix.src}/src internal/nixparser/treesitter_nix/upstream
  '';

  postInstall = ''
    mv $out/bin/tsgo $out/bin/typenix
    mkdir -p $out/share/nixlibs
    cp internal/bundled/nixlibs/*.d.ts $out/share/nixlibs/
  '';

  passthru.autobump = true;
  passthru.autobumpArgs = [ "--version=branch" ];

  meta = {
    description = "Full typing for Nix based on TypeScript";
    homepage = "https://github.com/ryanrasti/typenix";
    license = lib.licenses.asl20;
    mainProgram = "typenix";
  };
}
