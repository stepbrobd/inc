use std::process::Stdio;
use std::time::Duration;

use anyhow::{Context, Result};
use tokio::io::AsyncReadExt;
use tokio::process::Command;

const PIPE_CHUNK: usize = 8192;

pub struct RunResult {
    pub body: String,
    pub exit: Option<i32>,
    pub timed_out: bool,
    pub truncated: bool,
}

pub async fn execute(mut cmd: Command, timeout: Duration, cap: usize) -> Result<RunResult> {
    cmd.stdin(Stdio::null())
        .stdout(Stdio::piped())
        .stderr(Stdio::piped())
        .kill_on_drop(true);
    // own process group so a timeout kills the whole subtree, not just the shell
    cmd.process_group(0);

    let mut child = cmd.spawn().context("spawn")?;
    let pid = child.id().context("child pid")? as i32;

    let out = child.stdout.take().expect("piped");
    let err = child.stderr.take().expect("piped");
    let out_task = tokio::spawn(drain(out, cap));
    let err_task = tokio::spawn(drain(err, cap));

    let timed_out = tokio::time::timeout(timeout, child.wait()).await.is_err();
    if timed_out {
        // kill the whole group, not just the shell. the child is the group
        // leader, so its pid is the pgid. nix wraps killpg(2) safely.
        let _ = nix::sys::signal::killpg(
            nix::unistd::Pid::from_raw(pid),
            nix::sys::signal::Signal::SIGKILL,
        );
    }
    let status = child.wait().await.context("wait")?;
    let (o, o_cut) = out_task.await.context("stdout reader")?;
    let (e, e_cut) = err_task.await.context("stderr reader")?;

    let mut body = String::from_utf8_lossy(&o).into_owned();
    if !e.is_empty() {
        body.push_str("\n--- stderr ---\n");
        body.push_str(&String::from_utf8_lossy(&e));
    }

    Ok(RunResult {
        body,
        exit: status.code(),
        timed_out,
        truncated: o_cut || e_cut,
    })
}

// read a pipe to EOF, keeping at most `cap` bytes but still draining the rest so
// the child never blocks on a full pipe. returns the kept bytes and whether more
// were discarded.
async fn drain<R: AsyncReadExt + Unpin>(mut r: R, cap: usize) -> (Vec<u8>, bool) {
    let mut kept = Vec::new();
    let mut truncated = false;
    let mut buf = [0u8; PIPE_CHUNK];
    loop {
        match r.read(&mut buf).await {
            Ok(0) | Err(_) => break,
            Ok(n) => {
                if kept.len() < cap {
                    let take = n.min(cap - kept.len());
                    kept.extend_from_slice(&buf[..take]);
                    truncated |= take < n;
                } else {
                    truncated = true;
                }
            }
        }
    }
    (kept, truncated)
}
