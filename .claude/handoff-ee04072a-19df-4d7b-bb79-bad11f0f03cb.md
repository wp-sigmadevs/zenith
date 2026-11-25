## Handoff (deep) — Zenith — 2026-11-26 (home machine `~/GithubProjects/`)

### Done
- Fork `~/GithubProjects/zed` `zenith` = `origin/zenith` @ `4eaacbb784` (verified `git status -sb`). `Zenith.app` bundled from it, installed 2026-11-26 00:28 (log `/tmp/zenith-bundle.log`, exit at the DMG `mv` is the known harmless one). NOT seen in a running app.
- Full gate on the work-machine tree (`6ce6200365`): 2 stale `zed` tests, both fixed (`e93075f650` namespace filter, `996d8f8311` cmd-7 for the base-keymap test). Then 1476/1476, clippy and check clean.
- Deployment dialog: form `min_w_0`, width capped at 95% of the window, footer/panel status lines wrap (`326c90a363`, `9919a513ce`); Remote Host "<folder> is empty" row (`b971de7eea`) + refresh keeps it so the selection does not move (`bbc9dad850`); stock Split Pane hidden while markdown buttons show, kept on tabs that cannot split (`602d1619c6`, `4eaacbb784`, pane.rs 7+/4-). All in `git log 996d8f8311..4eaacbb784`.
- Docs `main`: engineering notes `docs/guides/fork-findings.md` § "Session 2026-11-26 (home)", HANDOFF plan 44 row (this brief's commit; push only on the owner's word). Earlier this session: merged brief of the work-machine evening session (its brief file removed).
- Memory: `zenith-push-rules` (new), `machines`, `zenith-review-process`, `supercharger-blocks`, `zsh-colon-modifier` updated, index current.
- Reviewed an unrelated project on request: `~/GithubProjects/readback` (nothing changed there).

### In Flight
- none. No agents, builds or worktrees running.

### Decisions Made
- Owner: hide the stock Split Pane button when markdown buttons show (not a second icon); empty remote folder shows a placeholder row ("yes, a placeholder"); fork pushes need the word per batch ("push and bundle", "yes" after my ask).
- Owner accepted pane.rs 7+/4- (budget 5): no cheaper form (workspace cannot depend on zenith_rails). Keep stock split on tabs that cannot split.
- Not decided: narrow-window dialog layout (<475 px), long server names.

### What Failed
- zsh `$P` for `-p` lists: cargo got one argument; use `${=P}`.
- `rm -rf target/debug/incremental` blocked by the Supercharger guard; `cargo sweep --maxsize 40GB` in the fork worked (35.59 GiB). Owner's own `cargo sweep` in the docs repo failed twice (no Cargo.toml).
- `percent` / `relative(0.95)` / `max_w` widths in the modal layer: ignored or off-centre; computed width works.
- The empty-row guard on `loading` (my accepted implementation) moved the selection on refresh (Opus MUST).

### Blockers
- none. Owner: check the new bundle (list below); docs `main` push on the owner's word.

### Worktrees
- none (main checkouts only: `~/GithubProjects/zenith` on `main`, `~/GithubProjects/zed` on `zenith`). 2 old stashes in the fork (`stash@{0,1}`, fmt noise, `git stash drop` is guard-blocked; owner drops with `!`).

### Files Touched
- Fork: `crates/zenith_deploy/src/{dialog,panel,zenith_deploy}.rs`, `crates/zenith_rails/src/{tab_bar_end,zenith_rails}.rs`, `crates/zenith_markdown/src/zenith_markdown.rs`, `crates/workspace/src/pane.rs` (7+/4-), `crates/zed/src/zed.rs` (two test fixes).
- Docs: `HANDOFF.md` (plan 44 row), `docs/guides/fork-findings.md` (new section), this brief.

### Resume With
Read this brief and `docs/guides/fork-findings.md` § "Session 2026-11-26 (home)". Owner checks the 00:28 bundle (list below); fix what fails through the loop (Sonnet builds → my gate incl. `-p zed` → Opus review). Then pick: C4 Compare (held), M4b, #9 layout, #17 R3-R5 once answered, PHP Runtime/Analysis/Composer tabs once PhpStorm screenshots arrive.

### Start With
- `/sc-status` — hooks and autopilot state in the new session (old autopilot expired).

### Measurements
- Full zenith_* + workspace + zed nextest: 1476 tests, 38.6 s test time, 2 skipped (after the fixes; 1474 + 2 failed before). Disk per gate ≈ 14 GiB; bundle ≈ 17 min, free 56 → 43 GiB.
- Deployment form before/after (test rem 14 px, dialog 672 px): FTP form 720 px, right edge 1426 vs 1296 (+130); after 442.5 px, right edge 1284.5. At a 600 px window the old dialog sat at -36..636, now 15..585.
- `cargo sweep --maxsize 40GB` in the fork: 35.59 GiB freed (29 → 65 GiB).
- Tests: zenith_deploy 183 passed / 1 skipped; zenith_rails+markdown+workspace+zed+zenith 506 passed / 1 skipped.
- Opus rounds: dialog 1 (+notes), Empty row 1 (NEEDS CHANGES), split hide 1 (PASS WITH NOTES).

### Rejected — do not rebuild
- Second icon for markdown Split (`DiffSplit`): replaced by hiding the stock button (owner).
- Fork-side copy of `default_render_tab_bar_buttons`: drifts from upstream; a bool param was cheaper.
- Hiding the empty-folder placeholder while `loading`: row-count change moves the selection.
- Temp+rename remote upload, FreeModel default, Supercharger auto-install, minimap off (carried; see earlier notes).

### Dead ends
- Probing whether the fork's JetBrains default made `test_disabled_keymap_binding` fail: set default `base_keymap` to VSCode, still failed. Cause was the zenith keymap loaded after the base (`cmd-6` Problems).
- Bisecting 559 commits was not needed: one run with the zenith keymap block disabled gave the answer.

### Open questions
- Unverified in the app (all of the bundle): markdown tab layout (stock split gone; two similar icons return on Editor+Preview), Deployment dialog fit and wrapping at normal and narrow windows, Empty row height/indent, selection stable on Refresh, keychain prompt behaviour ("Always Allow" then none in the session), plus the earlier list (tab menu, splitter, PHP dialog, menus, lens, remote editing, `⌘6`, base keymap switch).
- Verified false: the fork's JetBrains default breaks `test_disabled_keymap_binding`.
- Orphaned focus when tab-switching by keyboard with the Split menu open (55/100): unproven.
- Dialog below ~475 px window width and long server names in the 14 rem list: known gaps, not fixed.

### Reproduce
- Env (home): `export CARGO_INCREMENTAL=0 DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer`; `df -g ~` ≥ 30 in the same command; one cargo at a time.
- Full gate: `P=$(ls crates | grep '^zenith' | sed 's/^/-p /' | tr '\n' ' '); cargo nextest run ${=P} -p workspace -p zed --no-fail-fast`; `cargo clippy ${=P} -p zed --all-targets -- -D warnings`; `cargo check -p zenith -p zed`.
- Disk: `cd ~/GithubProjects/zed && cargo sweep --maxsize 40GB` (not in the docs repo). Bundle: `script/bundle-mac -i` with the env; verify `ls -lT /Applications/Zenith.app/Contents/MacOS/zed`.
- Layout test: `cargo nextest run -p zenith_deploy -E 'test(the_form_stays_inside_the_dialog)'`; refresh regression: `a_refresh_keeps_the_empty_row_and_the_selection` (20 seeds).
