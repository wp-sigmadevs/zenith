# Upstream sync log

Procedure and kill criteria: `plan/13-maintenance.md`, `plan/README.md`.

| Date | Machine | Upstream | Commits | Conflicts | Time | Gate |
|---|---|---|---|---|---|---|
| 2026-11-19 | home | `4a7d10473a` | 69 | 2: `client/zed_urls.rs` (took upstream's deletion of `shared_agent_thread_url`), `onboarding/onboarding.rs` (took upstream layout, kept Zenith strings) | ≈ 15 min incl. checks | `cargo check -p zed` 1 m 14 s, 0 errors; nextest zenith_* + icons 103/103 (1 m 41 s) |
| 2026-11-22 | home | `d31d1074a0` | 35 | 1: `paths/paths.rs` (took upstream's removal of unused `devcontainer_dir`, #67199; kept `.zenith`/`.zed` fns). Build fix: upstream dropped `Project::local_terminal_handles` (#67200), re-added as a Zenith block at the end of `project/terminals.rs` (run widget Stop) | ≈ 20 min incl. checks | `cargo check -p zed` 0 errors; nextest zenith_* 672/672; clippy zenith_* clean. Merge `66bdccbd97` |

Flow used: `main` ff to `upstream/main` → merge `main` into `zenith` → merge `zenith` into `feat/look`; all three pushed. `rerere` enabled in this clone.
