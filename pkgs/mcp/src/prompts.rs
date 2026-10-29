// human and model facing strings for the server. kept apart from the wiring so
// the tool description and server instructions can be reviewed and edited on
// their own.

pub const RUN_TOOL: &str = "Run a command line and return its combined output, exit status, and timing. It runs with the service user's permissions and access, under /bin/sh by default. To use another shell (bash, fish, nushell, ...) resolve its absolute path first (request it in `packages`, run `command -v <shell>`) and pass that as `shell`. List nixpkgs attribute names in `packages` to put them on PATH for the call via `nix shell`, e.g. `tmux` or `ripgrep`. Treat as destructive: it can modify the system.";

pub const SERVER_INSTRUCTIONS: &str = "Shell access with the server user's permissions and access. The `run` tool executes a command line, under /bin/sh by default or a shell whose full path you pass, with optional nixpkgs packages pulled onto PATH for the call. Commands can change the system, confirm before each call.";
