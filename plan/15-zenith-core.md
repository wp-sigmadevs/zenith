# 15 — `zenith_core`: Shared Infrastructure (A1)

Status: ⬜ not built. The crate does not exist in the fork (checked 2026-11-25: no `crates/zenith_core`); still a Phase 1 item. Until then `secrets.rs` lives in `zenith_deploy` and the rebrand helper in the `zenith` crate (`brand.rs`).

## Goal

One crate for infrastructure every feature needs, so 04–31 don't each reinvent it. `store` is extracted from `zenith_local_history` on second use (05 owns its own `store.rs` first); refactor 04 onto it.

## Modules

| Module | Provides | Used by |
|---|---|---|
| `process` | Async process runner: cwd, env, prefix (Docker exec), streaming stdout/stderr lines, cancellation, timeout, exit status | 04, 07, 09, 11, 19, 21, 24, 25 |
| `paths` | Host ↔ container path mapping (bidirectional, longest-prefix), worktree-relative helpers | 07, 11, 18, 21 |
| `store` | SQLite store per feature (via Zed `db`/`sqlez`), migrations, blob store (content-addressed, zstd) | 05, 08, 12, 22, 28 |
| `jobs` | Background job queue: debounce, coalesce by key, priority, cancellation on workspace close | 05, 21, 27 |
| `mcp` | Tool registry: features register MCP tools (`name`, JSON schema, handler) consumed by 06 | 05, 07, 12, 21, 22 |
| `settings` | `ZenithSettings` root + per-feature typed sub-settings + `enabled` flag helper | all |
| `ui` | Shared components: tree view, filterable list, results table/grid (from 12), diff Item wrapper, empty states | 05, 07, 08, 12, 21, 24 |
| `detect` | Project detection: Composer (PSR-4 map), package.json, Laravel, WordPress (plugin/theme headers), Docker Compose; `detect.db_credentials` (DB creds from `.env` / `wp-config.php`, regex only) | 11, 12, 19, 20, 24, 25 |
| `secrets` | Keychain-only secret store over `cx.read/write/delete_credentials`; never the global credentials provider (plaintext on Dev, plan 37) | 12, 37 |
| `trace` | `tracing` span helpers + metrics feeding the perf view (18) | all |

## API sketch

```rust
// process
let run = zenith_core::process::Command::new("vendor/bin/phpunit")
    .args(["--log-junit", report])
    .cwd(root).prefix(interpreter.exec_prefix())
    .spawn(cx)?;               // returns handle: lines() stream, cancel(), wait()

// mcp
zenith_core::mcp::register(cx, Tool::new("history_list", schema, |args, cx| async { ... }));

// detect
let php = zenith_core::detect::composer(&fs, root).await?; // psr4: Vec<(prefix, dir)>
```

## Rules

- No UI logic in `process`/`store`/`jobs` (testable headless).
- Every async op cancellable; nothing blocks the main thread.
- Public API documented with one example each.
- Cross-crate dependencies on the tab-bar registry: `zenith_markdown -> zenith_rails` and `zenith_problems -> zenith_rails` (inspection widget, plan 44 #11, fork `zenith` @ `ecbee8f25d`). Shared UI hooks go through `zenith_rails`, not upstream files.

## Milestones

1. `settings`, `process`, `trace`.
2. `store` + `jobs`: extracted from `zenith_local_history` on second use, not built before 05.
3. `paths` + `detect`.
4. `mcp` registry (with 06).
5. `ui` components extracted as 05/07/12 need them (extract on second use, not before).

## Tests

Unit tests per module; `process` tests with real `sh -c` commands; `paths` property tests (round-trip map).

## Effort

1 week initial, grows with features.
