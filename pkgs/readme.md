# Package & Scope auto discovery/creation/override (with self overlay injection)

See implementations in
[lib/import-packages-tree.nix](../lib/import-packages-tree.nix) (import) and
[lib/local-packages-from.nix](../lib/local-packages-from.nix) (export).

Auto update GHA in [.github/workflows/bump.yaml](../.github/workflows/bump.yaml)
(opt in with `passthru.autobump`, default to false).
