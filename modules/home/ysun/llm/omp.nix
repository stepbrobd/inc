{ config, lib, pkgs, ... }:

{
  home.packages = [ pkgs.omp ];
  home.sessionVariables.PI_CONFIG_DIR = lib.removePrefix "${config.home.homeDirectory}/" "${config.xdg.configHome}/omp";

  xdg.configFile = {
    "omp/agent/AGENTS.md".source = ./context.md;
    "omp/agent/config.yaml" = {
      force = true;
      source = (pkgs.formats.yaml { }).generate "omp.yaml" {
        dev.autoqa = false;

        marketplace.autoUpdate = "notify";
        startup = {
          quiet = false;
          changelogMode = "summary";
          checkUpdate = false;
          setupWizard = false;
        };

        theme = {
          dark = "dark-nord";
          light = "dark-nord";
        };
        symbolPreset = "ascii";
        title.icons = "boring";
        composer.shape = "pi";

        statusLine = {
          preset = "ascii";
          separator = "ascii";
          contextLine = "annotated";
          sessionAccent = true;
          transparent = true;
          compactThinkingLevel = true;
          showHookStatus = true;
        };

        tui = {
          tight = false;
          resizeScrollback = "rebuild";
          imeSafeCursor = false;
          vimMode = true;
        };

        display = {
          shimmer = "classic";
          hideToolActivity = false;
          subagentLivePreview = true;
          showTokenUsage = true;
          showTurnTime = true;
          cacheMissMarker = true;
        };

        autocompleteMaxVisible = 10;
        showHardwareCursor = true;
        recap.enabled = false;
        error.notify = "on";

        doubleEscapeAction = "tree";
        treeFilterMode = "user-only";
        steeringMode = "one-at-a-time";
        defaultThinkingLevel = "xhigh";
        tools.approvalMode = "yolo";
        secrets.enabled = true;

        advisor = {
          enabled = false;
          reviewMode = "agent-end";
          continueSeverity = "blocker";
          syncBacklog = "off";
        };

        compaction = {
          enabled = true;
          reserveTokens = 32768;
          keepRecentTokens = 65536;
        };

        providers = {
          cacheRetention = "long";
          streamIdleTimeoutSeconds = 250;
        };
        retry = {
          enabled = true;
          maxRetries = 5;
          baseDelayMs = 5000;
        };

        astGrep.enabled = true;
        github.enabled = true;
        lsp.diagnosticsOnEdit = true;
        task = {
          enableEffort = true;
          enableLsp = true;
          isolation.enabled = false;
          showResolvedModelBadge = true;
        };
        worktree.onStart = "off";

        terminal = {
          showImages = true;
          showProgress = true;
        };

        images = {
          autoResize = true;
          blockImages = false;
        };
      };
    };
  };
}
