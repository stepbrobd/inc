{ lib, ... }:

{ pkgs, ... }:

{
  programs.opencode = {
    enable = true;

    settings = {
      autoupdate = false;
      theme = "nord";
    };
  }
  // lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
    package = pkgs.llm-agents.opencode;
  };

  programs.claude-code = {
    enable = true;
    package = pkgs.llm-agents.claude-code;
  };

  # programs.codex = {
  #   enable = true;
  # }
  # // lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  #   package = pkgs.llm-agents.codex;
  # };
}
