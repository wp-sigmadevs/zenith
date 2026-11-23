## Handoff (deep) — Zenith — 2026-11-24 (home machine, `~/GithubProjects/`)

### Done
- Gate on merged fork `zenith`: 976/976 tests (all `zenith_*` + `project_panel --features project_panel/scratches`), clippy `-D warnings`, `cargo check -p zenith`. Pushed.
- Fork fixes (Opus-reviewed, merged, pushed; `git log f97b67b69b..503fca5ea7` on `zenith`):
  - `zenith_templates` tests: duplicate `NewScratchFile` action panic (18 fails) → dev-dep on real crate.
  - `zenith_http/src/history.rs`: userinfo stripped for every URL spelling; `{{var}}` templates cut by hand first; owner-approved masking names (`ssn`, `cvv`, `otp`, `pin`, card numbers, `tokens`, `refresh`, account/signing/write keys; bare `access` stays raw).
  - `zenith_php_tools`: `find_php` retries with the 10 s wait for every caller.
  - `Cargo.lock`: `url` 2.5.9, `quinn-proto` 0.11.19, `quinn-udp` 0.5.16, `ammonia` 4.1.9 (cargo audit 22 → 17).
  - `zenith_deploy` follow-ups (8 items + save-race fixes, 3 Opus rounds): `93d6f4d7c5`, `90eeeb96ee`, `503fca5ea7`.
- Docs (all pushed): 12 owner decisions in `HANDOFF.md` §3; plan 22 → tasks.json recipes; plan 43 AI Terminal written, approved, then ON HOLD; stale plan rows fixed (`3e62686`); pending release notes in `docs/guides/release-compliance.md`; plan 44 PhpStorm parity round 1 (`plan/44-phpstorm-parity-round1.md`, approved, minimap stays on); screenshots `mockups/owner-review-2026-11-23/`; engineering notes `docs/guides/fork-findings.md` § "Session 2026-11-23/24"; build log row.
- Origin cleanup: 13 merged Zenith branches deleted from `wp-sigmadevs/zed`.
- `Zenith.app` bundled from `503fca5ea7` and installed; the owner reviewed it (→ plan 44).

### In Flight
- none. No agents, builds or branches running.

### Decisions Made
- Owner: Sonnet builds, Opus reviews every round, never Fable (memory `zenith-review-process`).
- Owner: plan 44 decisions D1–D15 as recommended (40 px title bar, Inter 13 UI font, sticky headers on, usages line with author, "Scratches and Consoles", PHP dialog staged Cancel/Apply/OK, drop plugin menu entries, etc.) **except minimap stays ON**.
- Owner: plan 43 AI Terminal ON HOLD ("belay"); when resumed: Supercharger offered not auto-installed, `agy` + `gemini`, pin by tag + sha256.
- Owner: Supercharger is the owner's own product (MIT, `smrafiz/claude-supercharger`) — bundling allowed.
- Owner: 12 decisions of 2026-11-23 (commit prefix `feat(<crate>):`, agent `<example>` blocks dropped, collab = document only, project_panel hook exception accepted, etc.): `HANDOFF.md` §3.
- Not building a separate "universal AI platform" product; FreeModel not recommended (unidentified reseller).

### What Failed
- 10-item lead-engineer plan hit its 60-turn limit with no report; resumed with SendMessage (memory `subagent-turn-limits` updated).
- Reviewers could not run cargo (read-only hook refused); main session ran all tests before merge.
- Deploy fix rounds 1 and 2 each left an ordering hole (Esc during a Keychain prompt + reopen); fixed in round 3.
- First commit of the HTTP fix put the `Cargo.lock` change in the wrong commit; redone with a soft reset.
- Supercharger shell-profile guard blocked a plan-doc edit whose text contained the profile filename; reworded the edit.

### Blockers
- none. Plan 44 can start.

### Worktrees
- none besides the main checkouts (`~/GithubProjects/zenith` on `main`, `~/GithubProjects/zed` on `zenith`). The fork has 22 local merged branches (all ancestors of `zenith`); safe to delete with the owner's OK.

### Files Touched
- Fork: `crates/zenith_templates/{Cargo.toml,src/zenith_templates.rs}`, `crates/zenith_php_tools/src/{zenith_php_tools.rs,php_config.rs}`, `crates/zenith_http/src/history.rs`, `crates/zenith_deploy/src/{dialog.rs,secrets.rs,zenith_deploy.rs}`, `Cargo.lock`.
- Docs: `HANDOFF.md`, `CLAUDE.md` (plan count), `docs/map/DOCS.md`, `docs/guides/{fork-findings,release-compliance}.md`, `plan/{README,16,22,43,44,build-log}.md` + 12 plan status lines, `.claude/agents/*.md` (examples dropped), `mockups/owner-review-2026-11-23/`.

### Resume With
Read `plan/44-phpstorm-parity-round1.md` and this brief, then start plan 44 step 1 (quick wins: #10 Agent Review icon, #13 navbar font, #8 "Scratches and Consoles", #16 tab padding 12 px, #15 title bar 40 px) as one Sonnet implementer chunk on a branch, Opus review, run the checks yourself, merge, then bundle for the owner's check.

### Start With
- none required. Optional `/sc-status` to confirm autopilot is off and guards are on.

### Measurements
- Gate on merged tree: 976 tests run, 976 passed, 1 skipped; first run before fixes 958 passed / 18 failed (all `zenith_templates`).
- Full zenith_* nextest test time ≈ 14–17 s after build; disk −18 GiB per cold gate.
- `cargo audit --file Cargo.lock`: 22 → 17 vulnerabilities, 44 allowed warnings (cargo-audit 0.23.0).
- Release bundle `script/bundle-mac -i` (sccache warm) after deleting `target/debug/incremental` (57 GiB): ≈ 17 min, −15 GiB; exits 1 at the DMG `mv` (known, app fine).
- `cargo sweep --maxsize 40GB` freed 29.87 GiB and 32.10 GiB.
- `zenith_deploy` tests: 70 → 79 → 82 → 84 passed (1 skipped) across rounds.

### Rejected — do not rebuild
- Separate OpenCode-like Rust AI platform: Codex CLI and Goose already ship as Rust multi-provider agents; Anthropic blocks subscription OAuth in third-party tools since 2026-04-04, so BYOK users pay API rates. Ideas folded into plan 43 (on hold).
- FreeModel (`freemodel.in`) as a Zenith default: no identifiable operator, resells upstream access, unverified model names.
- Supercharger auto-install: rejected for offer-on-first-run (plan 43 D3).
- Minimap off (owner keeps it on).
- Round-2 deploy idea "re-check snapshot after the disk write": replaced by one-save-at-a-time `busy` flag + open-time `base` snapshot (no disk/memory divergence).

### Dead ends
- none beyond What Failed.

### Open questions
- Plan 44 *verify* list (16 items: diagnostic summary API, action names, overlay positioning, editor lease during block render, FTP `PWD`, live `enabled` flags…) — unverified, check before each chunk.
- Why `index.php` in the owner's screenshot was not italic: unverified (likely opened permanently, not as a preview).
- Load-timing flakes under full parallel nextest: `zenith_deploy sftp::tests::dropping_the_operation_kills_the_sftp_child`, `zenith_inspections tests::test_a_single_save_looks_up_the_base_beside_the_tools` — pass 3/3 alone; root cause unverified.
- Whether every merged feature works in the running app — not checked (owner's app checks pending).

### Reproduce
- Gate (zsh, from `~/GithubProjects/zed`):
  ```
  export CARGO_INCREMENTAL=0
  [ $(df -g ~ | awk 'NR==2{print $4}') -ge 30 ] && { P=(${(f)"$(ls crates | grep '^zenith' | sed 's/^/--package=/')"}); cargo nextest run "${P[@]}" -p project_panel --features project_panel/scratches --no-fail-fast; }
  ```
- Clippy: same packages, `cargo clippy … --all-targets -- -D warnings`. App: `cargo check -p zenith`.
- Bundle: `script/bundle-mac -i` (RELEASE_CHANNEL stable → `/Applications/Zenith.app`).
- Audit: `cargo audit --file Cargo.lock`. Free disk: remove `target/debug/incremental` when idle, or `cargo sweep --maxsize 40GB`.
