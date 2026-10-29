{ inputs, lib, stdenv }:

let
  anchor = "--set DISABLE_INSTALLATION_CHECKS 1";
in
inputs.llm.packages.${stdenv.hostPlatform.system}.claude-code.overrideAttrs (prev: {
  postFixup =
    assert lib.hasInfix anchor prev.postFixup;
    lib.replaceStrings [ anchor ] [ "${anchor} --set BUN_OPTIONS --preload=${./summary.js}" ] prev.postFixup
    + "grep -qF '[AgentSummary] Timer fired' $out/bin/.claude-wrapped";
})
