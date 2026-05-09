{ stdenv, llm-agents }: llm-agents.claude-code.overrideAttrs {
  __noChroot = false;
  doInstallCheck = stdenv.hostPlatform.isLinux;
}
