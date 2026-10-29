// human and model facing strings for the server. kept apart from the wiring so
// the tool description and server instructions can be reviewed and edited on
// their own.

pub const RUN_TOOL: &str = "Run a shell command as the server's user and return its combined output, exit status, and timing. Runs with the user's PATH, tools, and SSH keys. Treat as destructive: it can modify the system and act with the user's credentials.";

pub const SERVER_INSTRUCTIONS: &str = "Shell access as the server's user. The `run` tool executes a command line under the configured shell. Commands can change the system and use the user's credentials, so confirm before each call.";
