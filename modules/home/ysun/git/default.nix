{ config, pkgs, ... }:

{
  # colored diff tool
  programs.delta = {
    enable = true;
    enableGitIntegration = true;
    options = {
      features = "collared-trogon";
      navigate = true;
      side-by-side = true;
    };
  };

  programs.git = {
    enable = true;

    includes = [{ path = "${pkgs.delta}/share/themes.gitconfig"; }];

    settings = {
      user.name = "Yifei Sun";
      user.email = "ysun@hey.com";

      # signing
      gpg.format = "ssh";
      commit.gpgsign = "true";
      user.signingkey = "${config.home.homeDirectory}/.ssh/id_ed25519";

      # misc
      branch.sort = "-committerdate";
      color.ui = true;
      column.ui = "auto";
      commit.verbose = true;
      core.autocrlf = "input";
      core.fsmonitor = true;
      core.sshCommand = "ssh -o TCPKeepAlive=yes -o ServerAliveInterval=60";
      core.untrackedCache = true;
      diff.algorithm = "histogram";
      diff.colorMoved = "plain";
      diff.mnemonicPrefix = true;
      diff.renames = true;
      diff.sops.textconv = "sops decrypt";
      fetch.all = true;
      fetch.prune = true;
      fetch.pruneTags = true;
      fetch.writeCommitGraph = true;
      filter.lfs.clean = "git-lfs clean -- %f";
      filter.lfs.smudge = "git-lfs smudge -- %f";
      help.autocorrect = "prompt";
      init.defaultBranch = "master";
      lfs.sshTransfer = "never";
      merge.conflictstyle = "zdiff3";
      pull.rebase = true;
      push.autoSetupRemote = true;
      push.default = "upstream";
      push.followTags = true;
      rebase.autoSquash = true;
      rebase.autoStash = true;
      rebase.updateRefs = true;
      rerere.autoupdate = true;
      rerere.enabled = true;
      submodule.recurse = true;
      tag.sort = "version:refname";
    };
  };
}
