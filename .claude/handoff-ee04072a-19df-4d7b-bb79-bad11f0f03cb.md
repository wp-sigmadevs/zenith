## Handoff (deep) — Zenith — 2026-11-26 late (home machine `~/GithubProjects/`)

### Done
- Fork `~/GithubProjects/zed` `zenith` = `origin/zenith` @ `939b240ac7` (pushed on the owner's "push"; verified `git status -sb`). Since `4eaacbb784`: `db58d37b03` fix(zenith_http) truncated JSON response body stored unmasked in history; `939b240ac7` comment fix. Details: `docs/guides/fork-findings.md` § "Session 2026-11-26 late (home)".
- Earlier today (all pushed): 2 stale `zed` tests fixed (`e93075f650`, `996d8f8311`), Deployment dialog overflow (`326c90a363`, `9919a513ce`), Remote Host Empty row (`b971de7eea`, `bbc9dad850`), stock Split hidden on markdown tabs (`602d1619c6`, `4eaacbb784`).
- Gate on `db58d37b03`: 1493/1493 (2 skipped), clippy, `cargo check -p zenith -p zed`. Sabotage by me: guard disabled → exactly the 2 new truncation tests fail. Opus review PASS WITH NOTES (no MUST); SHOULD (multipart comment) fixed in `939b240ac7`. After that comment-only commit only `zenith_http` tests (60/60) and its clippy were re-run, not the full gate.
- Worktree `~/GithubProjects/zed-httpmask` and branch removed. Fork: only the main checkout.
- Replay kit work for `readback-e2` (another Claude session): sent 21 past fixes as cases (message text, not in the repo); sent status of the c18 fix twice (not-merged, then merged-not-pushed). No message yet that it is PUSHED.
- Docs `main` = `origin/main`; this brief + notes + HANDOFF row + memory edits are uncommitted (`HANDOFF.md`, `docs/guides/fork-findings.md`, this file).
- Memory: `zenith-review-process` (agent worktree gotcha, peer-report loop), `zenith-push-rules` (peer request ≠ owner word) updated.

### In Flight
- none. No agents, builds, worktrees running.

### Decisions Made
- Owner: "go" to fix the c18 leak through the normal loop; "push and delete the worktree" (fork only; worktree was already gone).
- Truncated JSON body that cannot be masked → placeholder `[body not stored: truncated, secrets could not be masked]`. Form/multipart NOT widened (Opus: a prefix cut leaves no secret value; widening drops HTML/text and fixes nothing).
- Earlier (carried): hide stock Split on markdown tabs; empty remote folder shows a placeholder row; pane.rs 7+/4- accepted; pushes need the owner's word per batch.

### What Failed
- Agent `isolation: "worktree"` created a worktree of the docs repo, not the fork; the implementer made `zed-httpmask` itself.
- Earlier: zsh `$P` for `-p` lists (use `${=P}`); `rm -rf target/debug/incremental` blocked (use `cargo sweep --maxsize 40GB` inside the fork); modal percent/max_w widths.

### Blockers
- none. Owner: bundle (installed `Zenith.app` @ 00:28 predates the leak fix and everything after `4eaacbb784`), check the app (list below), docs `main` commit/push on the owner's word.

### Worktrees
- none (main checkouts only: `~/GithubProjects/zenith` on `main`, `~/GithubProjects/zed` on `zenith`). 2 old stashes in the fork (`stash@{0,1}`, `git stash drop` is guard-blocked; owner drops with `!`).

### Files Touched
- Fork: `crates/zenith_http/src/history.rs` (+118/-3: `may_be_json`, `UNMASKABLE_BODY`, guard in `HistoryDir::append`, 3 tests). 0 upstream lines.
- Docs: `HANDOFF.md` (plan 44 row), `docs/guides/fork-findings.md` (new section), this brief.

### Resume With
Read this brief and `docs/guides/fork-findings.md` § "Session 2026-11-26 late". Tell `readback-e2` the c18 fix is pushed (`939b240ac7`), then wait for the owner: bundle/app check results, or pick C4 Compare (held), M4b, #9 layout, #17 R3-R5, or the NDJSON/multipart masking gaps.

### Start With
- `/sc-status` — hooks and autopilot state in the new session.

### Measurements
- Full gate `db58d37b03`: 1493 tests, 2 skipped, 43.463 s test time (1476 before; +17 = new tests plus the tree's own growth, not itemised). `zenith_http`: 60 passed. Sabotage: 14 `disk_history` tests, 2 failed with the guard off (`…drops_a_cut_off_json_body_it_cannot_mask`, `…by_its_shape_without_a_content_type`), 12 passed.
- Disk during the gate: 43 GiB free before (`df -g ~`), shared target dir, no second build cache.
- Replay list: 21 cases (18 escapes, 3 review-caught: `bbc9dad850`, `4eaacbb784`, `16b037135e`); introducing commits blame-only, all unconfirmed.

### Rejected — do not rebuild
- Placeholder for every truncated body that masking returned `None` for: would drop large HTML/text from history, closes no leak (Opus).
- Masking before the runner truncates: needs a second 10 MiB parse in memory; the append-side guard covers every path (one non-test caller, `history_view.rs:79`).
- Earlier (carried): second icon for markdown Split; fork-side copy of `default_render_tab_bar_buttons`; hiding the Empty row while loading; temp+rename remote upload; FreeModel default; Supercharger auto-install.

### Dead ends
- BOM handling in `serde_json::from_str` (Opus ~60% it rejects a leading BOM): not probed, harmless either way.
- Earlier: probing the JetBrains default as the cause of `test_disabled_keymap_binding` (verified false; the zenith keymap `cmd-6` was the cause).

### Open questions
- Unverified in the app: everything bundled at 00:28 (markdown tab layout, Deployment dialog fit, Empty row, Refresh selection, keychain "Always Allow") and the whole truncated-body fix (not bundled).
- Unverified: whether existing history files on disk already hold unmasked tokens from >10 MiB responses (no scan done).
- Known gaps, not fixed: complete `application/x-ndjson` response with secrets stored unmasked (hand to security-engineer); multipart without `boundary=` never masked; truncated text starting with `[` becomes the placeholder (accepted); dialog below ~475 px; long server names; orphaned focus with the Split menu open (55/100).
- Replay introducing_sha values: unconfirmed until someone other than the reviewer reads each.

### Reproduce
- Env (home): `export CARGO_INCREMENTAL=0 DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer`; `df -g ~` ≥ 30; one cargo at a time.
- Full gate: `P=$(ls crates | grep '^zenith' | sed 's/^/-p /' | tr '\n' ' '); cargo nextest run ${=P} -p workspace -p zed --no-fail-fast`; `cargo clippy ${=P} -p zed --all-targets -- -D warnings`; `cargo check -p zenith -p zed`.
- Leak tests: `cargo nextest run -p zenith_http disk_history`. Sabotage: cp `history.rs` aside, trap-restore, change `None if response.truncated` to `None if false && response.truncated`; the 2 truncation tests must FAIL.
- Disk: `cd ~/GithubProjects/zed && cargo sweep --maxsize 40GB`. Bundle: `script/bundle-mac -i` with the env; verify `ls -lT /Applications/Zenith.app/Contents/MacOS/zed`.
