// audit trail. every security-relevant event is written twice: as a tracing
// event on the `audit` target (which systemd routes to the journal) and, when
// MCP_AUDIT_LOG is set, as one json line appended to a durable file that
// outlives journal rotation. a per-process call counter ties a command's start
// record to its end record so a hang or crash still leaves the start on record.

use std::fs::{File, OpenOptions};
use std::io::Write;
use std::sync::Mutex;
use std::sync::atomic::{AtomicU64, Ordering};
use std::time::{SystemTime, UNIX_EPOCH};

use anyhow::{Context, Result};
use serde_json::{Value, json};

pub struct Audit {
    file: Option<Mutex<File>>,
    seq: AtomicU64,
}

impl Audit {
    pub fn new(path: Option<&str>) -> Result<Self> {
        let file = match path {
            Some(p) => Some(Mutex::new(
                OpenOptions::new()
                    .create(true)
                    .append(true)
                    .open(p)
                    .with_context(|| format!("opening audit log {p}"))?,
            )),
            None => None,
        };
        Ok(Self {
            file,
            seq: AtomicU64::new(0),
        })
    }

    pub fn next_call(&self) -> u64 {
        self.seq.fetch_add(1, Ordering::Relaxed)
    }

    pub fn record(&self, event: &str, mut fields: Value) {
        let ts = SystemTime::now()
            .duration_since(UNIX_EPOCH)
            .map(|d| d.as_millis())
            .unwrap_or(0);
        if let Value::Object(map) = &mut fields {
            map.insert("event".into(), json!(event));
            map.insert("ts".into(), json!(ts as u64));
        }
        tracing::info!(target: "audit", %fields);
        if let Some(f) = &self.file
            && let Ok(mut g) = f.lock()
        {
            let _ = writeln!(g, "{fields}");
            let _ = g.flush();
        }
    }
}
