# Build log (plan 17)

Work machine (macOS, Apple Silicon), Rust 1.98.1, fork branch `feat/look`.

| Date | Change | Measure | Result |
|---|---|---|---|
| 2026-11-19 | Before (`debug = "limited"`, no sccache) | `target/` size | 86 GiB (`target/debug` 69 GiB, accumulated) |
| 2026-11-19 | Before | `cargo check -p zenith` after touching one zenith file | 15.7 s |
| 2026-11-19 | `cargo clean --profile dev` + `[profile.dev] debug = "line-tables-only"` (fork `.cargo/config.toml`, `10757fd480`) + sccache (cold) | clean `cargo nextest run -p zenith_todo` | 14 m 51 s; `target/debug` 9 GiB |
| 2026-11-19 | Same | first `cargo check -p zenith` after the wipe (builds check metadata) | 4 m 01 s; `target/debug` 11 GiB |
| 2026-11-19 | Same, warm | `cargo check -p zenith` after touching one zenith file | 4.0 s |
| 2026-11-19 | Same, warm | `cargo nextest run -p zenith_todo` after touching one file | 11.2 s |
| 2026-11-19 | Release, after core edits (`settings_content`, `editor`) | `script/bundle-mac -i` | 162 m 14 s (9733.52 s) |
| 2026-11-19 | Release, `zenith_todo` change only (+ `editor` dirtied by a stopped build) | `script/bundle-mac -i` | 47 m 09 s (2829.35 s) |
| 2026-11-23 | Release (home, sccache warm), `zenith` @ `503fca5ea7`, after removing `target/debug/incremental` (57 GiB) | `script/bundle-mac -i` | ≈ 17 m; disk −15 GiB; known exit 1 at the DMG `mv` |

Notes:
- `bundle-mac -i` exits 1 after installing (the DMG `mv` step fails); the installed app is fine.
- sccache caches third-party crates only (Cargo passes `-C incremental` for workspace crates, which sccache skips). First run: 0 hits / 1026 misses; gains show on the next clean or branch switch. Cache: `~/Library/Caches/Mozilla.sccache`, 10 GiB cap.
- sccache is enabled per folder: `~/GithubRepos/.cargo/config.toml` (zed, iremote-zed); `~/GithubRepos/shopify/.cargo/config.toml` sets `rustc-wrapper = ""` so Shopify Functions build without it.
- `target/debug` grows with each crate tested; trim with `cargo sweep --time 14` or `cargo clean -p <crate>` (never while a build runs).
- Not yet measured: clean `cargo build -p zed` and a release bundle with the new profile; second clean build with a warm sccache.
