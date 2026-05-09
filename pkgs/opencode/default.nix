{ stdenv, llm-agents }: llm-agents.opencode.overrideAttrs {
  doInstallCheck = stdenv.hostPlatform.isLinux;
}
