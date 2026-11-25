use std::sync::Arc;
use std::time::{Duration, Instant};

use rmcp::handler::server::wrapper::Parameters;
use rmcp::model::{CallToolResult, ContentBlock, Implementation, ServerCapabilities, ServerConfig};
use rmcp::service::RequestContext;
use rmcp::{ErrorData, RoleServer, ServerHandler, tool, tool_handler, tool_router};
use serde::Deserialize;
use serde_json::json;

use crate::audit::Audit;
use crate::auth::{HDR_SESSION, HDR_SUBJECT};
use crate::config::Settings;
use crate::{exec, prompts};

// shell used when the caller passes none; a full path is expected
const DEFAULT_SHELL: &str = "/bin/sh";

#[derive(Debug, Deserialize, schemars::JsonSchema)]
struct RunArgs {
    /// command line passed to the shell with -c
    command: String,
    /// absolute path to the shell, default /bin/sh. to use bash, fish, nushell,
    /// etc, resolve its full path first (request it in `packages` and run
    /// `command -v <shell>`), then pass that path here.
    #[serde(default)]
    shell: Option<String>,
    /// nixpkgs attribute names to put on PATH for this call via `nix shell`,
    /// e.g. ["tmux", "ripgrep"] runs under `nix shell nixpkgs#tmux nixpkgs#ripgrep`.
    #[serde(default)]
    packages: Vec<String>,
    /// working directory, defaults to the service user's home
    #[serde(default)]
    cwd: Option<String>,
    /// wall-clock timeout in seconds, capped by the server
    #[serde(default)]
    timeout_secs: Option<u64>,
}

#[derive(Clone)]
pub struct Shell {
    settings: Arc<Settings>,
    audit: Arc<Audit>,
}

#[tool_router]
impl Shell {
    pub fn new(settings: Arc<Settings>, audit: Arc<Audit>) -> Self {
        Self { settings, audit }
    }

    #[tool(description = prompts::RUN_TOOL)]
    async fn run(
        &self,
        Parameters(args): Parameters<RunArgs>,
        ctx: RequestContext<RoleServer>,
    ) -> Result<CallToolResult, ErrorData> {
        let s = &self.settings;
        let (subject, session) = caller(&ctx);
        let timeout = args
            .timeout_secs
            .map(Duration::from_secs)
            .unwrap_or(s.default_timeout)
            .min(s.max_timeout);
        let home = std::env::var("HOME").unwrap_or_else(|_| "/".to_string());
        let cwd = args.cwd.clone().unwrap_or(home);
        let shell = args.shell.as_deref().unwrap_or(DEFAULT_SHELL);

        let call = self.audit.next_call();
        self.audit.record(
            "run_start",
            json!({
                "call": call, "subject": subject, "session": session,
                "command": args.command, "shell": shell, "packages": args.packages,
                "cwd": cwd, "timeout_s": timeout.as_secs(),
            }),
        );

        let started = Instant::now();
        let outcome = exec::execute(
            shell,
            &args.packages,
            &args.command,
            &cwd,
            timeout,
            s.max_output_bytes,
        )
        .await;
        let elapsed = started.elapsed();

        match outcome {
            Ok(r) => {
                self.audit.record(
                    "run_end",
                    json!({
                        "call": call, "subject": subject,
                        "exit": r.exit, "timed_out": r.timed_out, "truncated": r.truncated,
                        "bytes": r.body.len(), "ms": elapsed.as_millis() as u64,
                    }),
                );
                let mut head = format!(
                    "exit: {}\nduration: {:.2}s",
                    r.exit
                        .map(|c| c.to_string())
                        .unwrap_or_else(|| "signal".to_string()),
                    elapsed.as_secs_f64()
                );
                if r.timed_out {
                    head.push_str(&format!("\ntimed out after {}s, killed", timeout.as_secs()));
                }
                if r.truncated {
                    head.push_str(&format!(
                        "\noutput truncated to {} bytes",
                        s.max_output_bytes
                    ));
                }
                Ok(CallToolResult::success(vec![ContentBlock::text(format!(
                    "{head}\n\n{}",
                    r.body
                ))]))
            }
            Err(e) => {
                self.audit.record(
                    "run_error",
                    json!({ "call": call, "subject": subject, "error": e.to_string() }),
                );
                Err(ErrorData::internal_error(
                    format!("spawn failed: {e}"),
                    None,
                ))
            }
        }
    }
}

#[tool_handler]
impl ServerHandler for Shell {
    fn get_info(&self) -> ServerConfig {
        ServerConfig::new(ServerCapabilities::builder().enable_tools().build())
            .with_server_info(Implementation::from_build_env())
            .with_instructions(prompts::SERVER_INSTRUCTIONS.to_string())
    }
}

fn caller(ctx: &RequestContext<RoleServer>) -> (String, Option<String>) {
    let parts = ctx.extensions.get::<axum::http::request::Parts>();
    let get = |name: &str| {
        parts
            .and_then(|p| p.headers.get(name))
            .and_then(|v| v.to_str().ok())
            .map(|s| s.to_string())
    };
    (
        get(HDR_SUBJECT).unwrap_or_else(|| "unknown".to_string()),
        get(HDR_SESSION),
    )
}
