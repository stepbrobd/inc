{ lib, stdenvNoCC }:

if stdenvNoCC.hostPlatform.isDarwin then
  (lib.getFlake "github:hraban/mac-app-util/8414fa1e2cb775b17793104a9095aabeeada63ef").packages.${stdenvNoCC.hostPlatform.system}.default.overrideAttrs
  {
    meta = {
      mainProgram = "mac-app-util";
      platforms = lib.platforms.darwin;
    };
  }
else
  stdenvNoCC.mkDerivation {
    pname = "mac-app-util";
    version = "0-unsupported";
    dontUnpack = true;
    meta.platforms = lib.platforms.darwin;
  }
