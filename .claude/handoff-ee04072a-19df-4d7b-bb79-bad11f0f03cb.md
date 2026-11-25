## Handoff (deep) — Zenith — 2026-11-26 night (home machine `~/GithubProjects/`)

### Done
- Fork `~/GithubProjects/zed` `zenith` @ `5635f4bd51`, 3 commits AHEAD of `origin/zenith` (unpushed; verified `git status -sb`). Pushed earlier today: `939b240ac7` (c18: cut-off JSON response stored unmasked).
- Merged locally, `zenith_http` only, 0 upstream lines: `c532dac48e` (A1 NDJSON line masking, A2 multipart without `boundary=`), `eeb2356c32` (round 2: whole-body parse first, boundary fallback, BOM, note kept), `5635f4bd51` (round 3: repeated-key-aware parse, json-seq RS framing, StreamDeserializer span rewrite, BOM sniff, empty-boundary filter). Gate on each: 1498 / 1502 / 1508 tests (2 skipped), clippy `-D warnings`, `cargo check -p zenith -p zed` green. Details: `docs/guides/fork-findings.md` § "Session 2026-11-26 night (home)".
- Worktree `zed-httpmask2` and branch removed (owner's word). Fork has only the main checkout.
- Verdicts sent to `readback-e2` (replay session): 21 replay cases; items 3-6 (3 confirmed by reading, 4 and 6 ruled out, 5 confirmed by reading); c18 pushed; review-round results; repeated-key LEAK confirmed. No message yet that A1/A2 are merged locally (it knows rounds 1-2 and the repeated-key result).
- Docs `main` = `origin/main` (b07c786 already pushed by owner); this brief + notes + HANDOFF row are uncommitted.

### In Flight
- none. No agents, builds, worktrees. 2 old stashes in the fork (`stash@{0,1}`; `git stash drop` guard-blocked; owner drops with `!`).

### Decisions Made
- Owner: "go, fix A1 A2 3 and 5" (one by one); "cut the agent and merge to zenith" (stopped the round-3 Opus review, merged locally, no push); "delete the worktree".
- Repeated key `{"token":"S","token":null}`: re-serialise the parsed form (earlier duplicate values dropped).
- Complete bodies keep an unparsable line as written; only a body the run marked truncated is checked for cut lines. Truncated + earlier line fails ⇒ whole body placeholder.
- Item 5 plan (not built): `AskFirst` when both stamps are `None` and sizes match; cost = a prompt per save on FTP without MDTM.

### What Failed
- Agent `isolation: "worktree"` makes a docs-repo worktree, not the fork (implementer must `git worktree add` itself).
- First A1/A2 fix introduced a regression (multi-line JSON under an ndjson type stored raw): my gate and the implementer's sabotage runs were green; only Opus caught it.
- Earlier today: zsh `$P` for `-p` lists (use `${=P}`); `rm -rf target/debug/incremental` blocked (use `cargo sweep --maxsize 40GB` in the fork).

### Blockers
- none. Owner: push the fork on the word (3 commits), bundle (installed `Zenith.app` @ 00:28 has NONE of today's masking fixes), app check, decide whether the unreviewed round 3 needs an Opus pass.

### Worktrees
- none (main checkouts only: `~/GithubProjects/zenith` on `main`, `~/GithubProjects/zed` on `zenith`).

### Files Touched
- Fork: `crates/zenith_http/src/history.rs` (+~650 incl. tests, masking pipeline), `crates/zenith_http/src/response.rs` (`TRUNCATION_NOTE_PREFIX`, +3/-2). 0 upstream lines.
- Docs: `HANDOFF.md` (plan 44 row), `docs/guides/fork-findings.md` (new section), this brief.

### Resume With
Read this brief and `docs/guides/fork-findings.md` § "Session 2026-11-26 night". Ask the owner: push the 3 unpushed fork commits? Opus pass on round 3 (`git diff eeb2356c32..5635f4bd51`)? Then build item 3 (Recent Files stale `file_target`) and item 5 (no-stamp same-size upload) one at a time through the loop. Tell `readback-e2` what merged.

### Start With
- `/sc-status` — hooks and autopilot state in the new session.

### Measurements
- Full gate (zenith_* + workspace + zed): round 1 1498, round 2 1502, round 3 1508 tests, 2 skipped, 38-40 s test time each. `zenith_http`: 60 → 65 → 69 → 75 tests.
- Diff sizes: c532dac48e history.rs +214/-7; eeb2356c32 +198/-63 (history.rs, response.rs); 5635f4bd51 +340/-70. Range 939b240ac7..5635f4bd51: 635 insertions, 23 deletions net (2 files).
- Repeated-key probe: `{"token":"S","token":null}` under `application/json` stored `{"token":"SECRETVAL","token":null}` before the fix (test `test_disk_history_masks_a_secret_key_repeated_with_null`).
- Disk: 35 GiB free during gates (`df -g ~`), shared `CARGO_TARGET_DIR=~/GithubProjects/zed/target`.
- Opus rounds on this chunk: 2 × NEEDS CHANGES, third stopped by owner before verdict.

### Rejected — do not rebuild
- Placeholder for every truncated body that masking could not mask (drops HTML/text, closes no leak).
- Masking before the runner truncates (second 10 MiB parse in memory).
- Whole-body placeholder for a cut NDJSON (fires on every truncated stream, drops complete lines); replaced by "only the last data line may fail".
- Earlier (carried): second Split icon for markdown; fork-side copy of `default_render_tab_bar_buttons`; hiding the Empty row while loading; FreeModel default; Supercharger auto-install.

### Dead ends
- BOM rejection by `serde_json::from_str` never probed (Opus ~60%); the fix strips the BOM either way.
- Smaller design alternative ("JSON-ish type not fully maskable ⇒ placeholder") was asked of Opus in round 3, which was stopped: unevaluated, not rejected.

### Open questions
- Unreviewed (round 3, `eeb2356c32..5635f4bd51`): byte-offset span rewrite on multibyte/CRLF/BOM, depth past serde_json's 128 recursion limit (stored raw?), numbers outside f64 range falling to per-record masking (`{"token":"S","n":1e999}`). Unverified, not verified false.
- Do existing history files on disk hold unmasked tokens? Not scanned.
- Item 3 and 5 reproduced? No, both confirmed by reading only.
- Everything bundled at 00:28 and none of the masking fixes seen in the app (owner check list: markdown tab layout, Deployment dialog, Empty row, Refresh selection, keychain prompt, tab menu, splitter, PHP dialog, menus, lens, remote editing, `⌘6`).
- Known gaps, unfixed: CR-only line separators, boundary found inside a value, nested multipart, `text/event-stream`, dialog below ~475 px, long server names, orphaned focus with Split menu open (55/100).

### Reproduce
- Env (home): `export CARGO_INCREMENTAL=0 DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer`; `df -g ~` ≥ 30; one cargo at a time.
- Full gate: `P=$(ls crates | grep '^zenith' | sed 's/^/-p /' | tr '\n' ' '); cargo nextest run ${=P} -p workspace -p zed --no-fail-fast`; `cargo clippy ${=P} -p zed --all-targets -- -D warnings`; `cargo check -p zenith -p zed`.
- Masking tests: `cargo nextest run -p zenith_http history`. Sabotage pattern: cp `history.rs` aside, trap-restore, disable one guard, the named tests must FAIL.
- Review the unreviewed range: `git -C ~/GithubProjects/zed diff eeb2356c32..5635f4bd51`.
- Disk: `cd ~/GithubProjects/zed && cargo sweep --maxsize 40GB`. Bundle: `script/bundle-mac -i` with the env; verify `ls -lT /Applications/Zenith.app/Contents/MacOS/zed`.
