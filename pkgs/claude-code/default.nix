{ inputs, stdenv }: inputs.llm.packages.${stdenv.hostPlatform.system}.claude-code
