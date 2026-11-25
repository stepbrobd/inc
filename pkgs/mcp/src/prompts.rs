// human and model facing strings for the server. kept apart from the wiring so
// the tool description and server instructions can be reviewed and edited on
// their own.

pub const RUN_TOOL: &str = "Run a command line and return its combined output, exit status, and timing. It runs with the service user's permissions and access, under /bin/sh by default, on this server or, when `host` names an ssh destination, on that machine. Pass the command exactly as for a local call. The server quotes it for the remote login shell, so do not wrap it in ssh, sh -c or a heredoc. To use another shell (bash, fish, nushell, ...) resolve its absolute path first (request it in `packages`, run `command -v <shell>`) and pass that as `shell`. List nixpkgs attribute names in `packages` to put them on PATH for the call via `nix shell` on the machine that runs it, e.g. `tmux` or `ripgrep`. On a remote host a timeout ends the ssh session, but the remote command may keep running. Treat as destructive: it can modify the system.";

pub const UPLOAD_TOOL: &str = "Create a short-lived link through which a person or an HTTP client sends one file to `path` on this server, or on the ssh `host`, without the bytes passing through you. Give the url to the user to open in a browser, or upload with curl from a sandbox that can reach it. The link accepts one upload, then expires. To write a small text file yourself use `run` with a heredoc.";

pub const DOWNLOAD_TOOL: &str = "Create a short-lived link from which a person or an HTTP client fetches the file at `path` on this server, or on the ssh `host`, without the bytes passing through you. Give the url to the user to open in a browser, or fetch it with curl from a sandbox that can reach it. To read a file yourself use `run` (cat, sed -n, head).";

pub fn instructions(hostname: &str) -> String {
    format!(
        "Shell access with the server user's permissions and access. This server runs on the host {hostname}. The `run` tool executes a command line here, or on another machine over ssh when `host` names it, under /bin/sh by default or a shell whose full path you pass, with optional nixpkgs packages pulled onto PATH for the call. `upload` and `download` return short-lived links that move a file between the user, or any HTTP client, and a path here or on a `host`. Commands can change the system, confirm before each call."
    )
}
