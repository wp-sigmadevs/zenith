# 17 — Build Optimization & Feature Flags (A4, A5)

> **Status (2026-11-22):** 🟨 tooling done (see Progress). Cargo feature flags merged in `zenith` (`2383de8081`, with plan 02).

## Goal

Fast edit-compile-run loop for Zenith development; ability to compile features out.

## A4 — Cargo features per Zenith crate

`crates/zenith/Cargo.toml`:
```toml
[features]
default = ["scratches", "local-history", "ide-server", "test-runner", "http", "refactor", "git-merge", "interpreters", "db", "ui", "wordpress", "templates", "inspections", "agent-worktrees"]
scratches = ["dep:zenith_scratches"]
db = ["dep:zenith_db"]
# ...one per crate
```
- `zenith::init` uses `#[cfg(feature = "...")]` per feature.
- Dev: `cargo run --no-default-features --features scratches,ui` → only what you're working on (heavy deps like sqlx skipped).
- Runtime toggle still exists via settings (`zenith.<feature>.enabled`) — compile-time flag is for build speed, runtime for users.

## A5 — Build speed

| Change | Expected gain | Where |
|---|---|---|
| `sccache` (`RUSTC_WRAPPER=sccache`) | faster clean builds / branch switches | `~/.cargo/config.toml` (local only) |
| `[profile.dev] debug = "line-tables-only"`, `split-debuginfo = "unpacked"` | faster link, smaller target | local `.cargo/config.toml`, not committed if upstream differs |
| Build only touched crate: `cargo check -p zenith_http`, `cargo test -p zenith_http` | seconds instead of minutes | habit |
| `cargo-nextest` | faster parallel tests | `cargo nextest run -p zenith_*` |
| `bacon` / `cargo watch -x 'check -p zenith_x'` | continuous feedback | dev loop |
| Keep `target/` on fastest disk, exclude from Spotlight & Time Machine | IO | macOS |
| Periodic `cargo sweep` / `cargo clean -p` | keeps target size under control (disk is tight) | monthly |

Install:
```sh
brew install sccache
cargo install cargo-nextest bacon cargo-sweep
```

## Measure

Record in `plan/build-log.md`: clean build time, incremental (touch one zenith file) time, `target/` size — before/after each change. Target: incremental < 60 s.

## Effort

1–2 days.

## Progress

- 2026-11-19 (A5): `line-tables-only` dev profile in fork `.cargo/config.toml` (`10757fd480`); `target/debug` wiped (69 GiB) and rebuilt smaller; sccache + cargo-nextest + bacon + cargo-sweep installed (setup in `HANDOFF.md` §1); sccache scoped to `~/GithubRepos` with a Shopify opt-out. Incremental `cargo check -p zenith` 15.7 s → 4.0 s. Numbers: `plan/build-log.md`.
- Left: A4 per-crate features already exist for shipped crates (`crates/zenith/Cargo.toml`); add one per new crate. Measure clean `cargo build -p zed` / bundle with the new profile.
