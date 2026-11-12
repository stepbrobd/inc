{ pkgs, ... }:

{
  programs.gh = {
    enable = true;
    settings.git_protocol = "ssh";
    extensions = with pkgs; [
      gh-actions-lock
      gh-dash
      gh-eco
      gh-f
      gh-stack
    ];
  };
}
