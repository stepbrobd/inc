// where a command runs. sshd hands the remote command to the user's login
// shell, whose syntax is unknown (nushell on this fleet), so the argv travels
// as base64 inside a single-quoted literal that sh, bash, fish and nu all read
// the same way, and only /bin/sh on the far side decodes and quotes it.

use anyhow::{Result, ensure};
use base64::Engine;
use base64::engine::general_purpose::STANDARD;
use tokio::process::Command;

// linux MAX_ARG_STRLEN, the login shell receives the bootstrap as one argument
const MAX_REMOTE_COMMAND: usize = 131_072;
const SSH_CONNECT_TIMEOUT_SECS: u32 = 10;

#[derive(Clone, Debug)]
pub enum Target {
    Local,
    Ssh(String),
}

impl Target {
    pub fn new(host: Option<String>) -> Self {
        host.map_or(Target::Local, Target::Ssh)
    }

    pub fn host(&self) -> Option<&str> {
        match self {
            Target::Local => None,
            Target::Ssh(h) => Some(h),
        }
    }

    // argv runs in cwd, or in the target user's home when cwd is none
    pub fn command(&self, argv: &[String], cwd: Option<&str>) -> Result<Command> {
        let (program, args) = argv.split_first().expect("non-empty argv");
        match self {
            Target::Local => {
                let mut c = Command::new(program);
                c.args(args);
                if let Some(d) = cwd {
                    c.current_dir(d);
                }
                Ok(c)
            }
            Target::Ssh(host) => {
                let mut c = Command::new("ssh");
                c.args(["-T", "-o", "BatchMode=yes", "-o"])
                    .arg(format!("ConnectTimeout={SSH_CONNECT_TIMEOUT_SECS}"))
                    .args(["--", host])
                    .arg(remote_command(argv, cwd)?);
                Ok(c)
            }
        }
    }
}

fn remote_command(argv: &[String], cwd: Option<&str>) -> Result<String> {
    let mut script = String::new();
    if let Some(d) = cwd {
        script.push_str(&format!("cd -- {} && ", quote(d)));
    }
    script.push_str("exec");
    for a in argv {
        script.push(' ');
        script.push_str(&quote(a));
    }
    let b64 = STANDARD.encode(script);
    let cmd = format!("/bin/sh -c 'eval \"$(printf %s {b64} | base64 -d)\"'");
    ensure!(
        cmd.len() < MAX_REMOTE_COMMAND,
        "command is {} bytes once encoded for ssh, the limit is {MAX_REMOTE_COMMAND}",
        cmd.len()
    );
    Ok(cmd)
}

// posix single quoting, only ever read by /bin/sh
fn quote(s: &str) -> String {
    format!("'{}'", s.replace('\'', r"'\''"))
}

#[cfg(test)]
mod tests {
    use super::*;
    use proptest::prelude::*;

    // run the bootstrap the way sshd would under a posix login shell and
    // print each argument the far side received, nul separated
    fn roundtrip(args: &[String], cwd: Option<&str>) -> Vec<u8> {
        let mut argv = vec![
            "/bin/sh".to_string(),
            "-c".to_string(),
            r#"pwd; for a; do printf '%s\0' "$a"; done"#.to_string(),
            "sh".to_string(),
        ];
        argv.extend_from_slice(args);
        let out = std::process::Command::new("/bin/sh")
            .arg("-c")
            .arg(remote_command(&argv, cwd).unwrap())
            .output()
            .unwrap();
        assert!(out.status.success(), "{out:?}");
        out.stdout
    }

    fn expected(args: &[String], cwd: &str) -> Vec<u8> {
        let mut v = format!("{cwd}\n").into_bytes();
        for a in args {
            v.extend_from_slice(a.as_bytes());
            v.push(0);
        }
        v
    }

    proptest! {
        #[test]
        fn argv_survives(args in prop::collection::vec("[^\u{0}]*", 0..6)) {
            prop_assert_eq!(roundtrip(&args, Some("/")), expected(&args, "/"));
        }
    }

    #[test]
    fn quoting_edges() {
        let args: Vec<String> = [
            "it's",
            "'",
            "''",
            "\\'",
            "$HOME",
            "`id`",
            "$(id)",
            "\"",
            "a\nb",
            "-e",
            "",
            "* ?",
            "~",
            "é 漢字",
        ]
        .map(String::from)
        .to_vec();
        let dir = std::env::temp_dir().join("it's a dir");
        std::fs::create_dir_all(&dir).unwrap();
        let dir = dir.canonicalize().unwrap();
        let dir = dir.to_str().unwrap();
        assert_eq!(roundtrip(&args, Some(dir)), expected(&args, dir));
    }
}
