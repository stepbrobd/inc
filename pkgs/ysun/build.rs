use std::fmt::Write;
use std::path::PathBuf;
use std::{env, fs, process};

use generator::Body;

// served with status 404 for every path the site lacks
const NOT_FOUND: &str = "/error";

fn main() {
    // template and code changes rebuild the generator, which reruns this script
    for dir in ["generator/assets", "generator/pages", "generator/public"] {
        println!("cargo::rerun-if-changed={dir}");
    }
    println!("cargo::rerun-if-env-changed=out");

    let out_dir = PathBuf::from(env::var_os("OUT_DIR").expect("cargo sets OUT_DIR"));
    let mut table = String::from("static SITE: &[(&str, Static)] = &[\n");
    let store = env::var("out")
        .ok()
        .filter(|path| path.starts_with("/nix/store/"));
    let mut root =
        PathBuf::from(env::var_os("CARGO_MANIFEST_DIR").expect("cargo sets CARGO_MANIFEST_DIR"));
    root.push("generator");
    let site = generator::render(&root, store.as_deref()).unwrap_or_else(|e| {
        eprintln!("{e}");
        process::exit(1)
    });
    for (i, entry) in site.entries.iter().enumerate() {
        let file = match &entry.body {
            Body::File(path) => path.clone(),
            Body::Bytes(bytes) => {
                let path = out_dir.join(i.to_string());
                fs::write(&path, bytes).expect("OUT_DIR is writable");
                path
            }
        };
        writeln!(
            table,
            "    ({:?}, Static {{ content_type: {:?}, cache_control: {:?}, etag: {:?}, body: include_bytes!({:?}) }}),",
            entry.path,
            entry.mime.header(),
            entry.cache.header(),
            entry.etag,
            file
        )
        .expect("writing to a String");
    }
    table.push_str("];\n");
    let not_found = site
        .entries
        .iter()
        .position(|entry| entry.path == NOT_FOUND)
        .unwrap_or_else(|| {
            eprintln!("no page at {NOT_FOUND}, which every unknown path serves");
            process::exit(1)
        });
    writeln!(table, "const NOT_FOUND: usize = {not_found};").expect("writing to a String");
    fs::write(out_dir.join("site.rs"), table).expect("OUT_DIR is writable");
}
