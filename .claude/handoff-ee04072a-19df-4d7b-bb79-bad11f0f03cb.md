## Handoff (deep) — Zenith — 2026-11-25 night (home machine `~/GithubProjects/`; merges the work-machine evening brief)

### Done
- State verified 2026-11-25: fork `~/GithubProjects/zed` `zenith` = `origin/zenith` @ `6ce6200365`; docs `main` = `origin/main` @ `ff4ae8b` (after this brief's commit: one local docs commit, push only on the owner's word). Clean trees. Only `main` + `zenith` branches, no worktrees; 2 old stashes (`stash@{0,1}`, fmt noise; `git stash drop` is guard-blocked, owner drops with `!`).
- Home stretch: #3+#6 tab-bar end @ `7f1980288a`, #18 Find splitter @ `217d6dfa88` (Opus rounds + unreviewed round 3 each), bundled `Zenith.app` from `217d6dfa88` (installed 2026-11-25 00:32), storage cleaned (27 → 62 GiB, 72 GiB free now).
- Work stretch (already in `zenith`, see `git log ecbee8f25d..6ce6200365`): #11 inspection widget + #18 follow-ups, #4 lens (indent fix, usages, author), #17-R1 rebrand + R2 keymap label, G1 pinned tabs one row, menu chunks 2-3, plan 37 M4a "Edit remote file" C1-C3 (`zenith_deploy`, 0 upstream lines). Details: `docs/guides/fork-findings.md` §§ "Session 2026-11-25 (home)", "(work)", "(work, later)", "(work, evening)"; HANDOFF §2 plan 44 row is current.
- Memory (home dir): `zenith-review-process` (2026-11-25 evidence), `machines` (disk 2026-11-25), new `zenith-push-rules`.

### In Flight
- none. No agents, builds or worktrees.

### Decisions Made
- Owner: one by one, build/fix plan 44; loop = Sonnet builds → main-session gate → fresh Opus review per round → fix rounds → `--ff-only` merge → owner decides push.
- Owner: M4a before M2/M3; in-place remote write; confirm once per server per session; C4 Compare HELD; block uploads in shared/non-local projects. Option A keymap label; Zed service names stay; Linux/Windows menus flattened until an upstream nested-submenu PR; five apparently-live features keep their restart prompt until checked in the app.
- Close All closes pinned tabs too (owner not asked). Fork pushes need the owner's word each batch; docs `main` too.

### What Failed
- Gate green but Opus found real bugs in every chunk (see Measurements); sabotage by agents did not catch M4a bugs.
- Round-3 fixes of tab-bar end and splitter were merged without a third Opus pass.
- `cargo sweep` run in the docs repo → "manifest path ... does not exist" (run it in the fork).
- Bundle script exits 1 at the DMG `mv` (harmless, app installs).
- Work machine: full gate SKIPPED by owner for `6ce6200365`; only `cargo check -p zenith -p zed` ran.

### Blockers
- none. Owner: push docs `main` when ready; check the new bundle.

### Worktrees
- none (main checkouts only: `~/GithubProjects/zenith` on `main`, `~/GithubProjects/zed` on `zenith`).

### Files Touched
- This pass: `docs/guides/fork-findings.md` (home section: disk/bundle bullet), this brief (replaces `.claude/handoff-a39798fb-…md`, merged here), memory `machines.md`, `zenith-push-rules.md`, `MEMORY.md`.

### Resume With
Read this brief + `docs/guides/fork-findings.md` § "Session 2026-11-25 (work, evening)". Run the full gate on `zenith` @ `6ce6200365` (below), rebundle `Zenith.app` (installed app is from `217d6dfa88`), then owner checks: Remote Host editing on a real FTP/SFTP host, lens, menus, Tools toggles, pinned-tab row, inspection widget, splitter/⋮, tab menu, PHP dialog. Then decide C4 Compare / M4b / #9 layout.

### Start With
- `/sc-status` — confirm hooks and autopilot state in the new session (autopilot from the old session has expired).

### Measurements
- Gate on `7f1980288a`/`217d6dfa88`: nextest 99 passed (rails/zed), clippy clean; round counts: tab-bar end 3, splitter 3 (Opus ×2 NEEDS CHANGES), tab menu 4, PHP dialog 3, M4a 6 review rounds.
- Upstream source lines: tab-bar end 3 (+4-line `#[path]` test hook), splitter 0, M4a 0.
- Disk: free 27 → 62 GiB after sweep + incremental removal; 72 GiB at 2026-11-25 evening. Bundle ≈ 17 min, ~15 GiB.
- Subagent cost per round ≈ 60-190k tokens implementer, 60-85k reviewer.

### Rejected — do not rebuild
- Manual `Workspace::zenith_activate_pane`; dispatching `git::CopyFilePermalink`/`OpenFilePermalink`/`FileHistory` from the pane; `tab_index` alone for dialog focus (base keymap `tab → menu::SelectNext` wins); resolving the tab menu target by captured `ix` (use `item_id`).
- Temp+rename for remote upload (resets remote mode/owner, leaves readable temp `.php`).
- FreeModel as default / separate AI platform / Supercharger auto-install / minimap off (carried).

### Dead ends
- `cx.notify()` removal is not detectable by gpui tests (harness repaints after each simulated event).
- A global `sed` over `zenith_local_history/src/tests.rs` renamed `wp-config.php` in five tests (reverted); `wp-config.php` matches private globs so the first test passed without the fix.

### Open questions
- Unverified in the app: everything since the 2026-11-25 00:32 bundle (tab menu on non-active/split panes, PHP dialog look, tab-bar end ⋮ + markdown buttons gap, splitter at short windows, M4a, lens, menus, rebrand, pinned row).
- Splitter pins popup size for the session after any handle mouse-down; dock panes untested for tab-bar end; stock vs markdown buttons may touch.
- An unrequested push of `feat/plan37-m4a-edit-remote` reached origin from the work session (source unknown; deleted). Check the push-guard hook.
- Owner pending: PhpStorm screenshots of PHP Runtime / Analysis / Composer Files tabs (not built); Close All pinned confirmation.

### Reproduce
- Env (home): `export CARGO_INCREMENTAL=0 DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer`; `df -g ~` ≥ 30 in the same command; one cargo at a time. Work machine uses `Xcode-27.2.0.app`.
- Gate: `cargo check -p zenith -p zed`; `cargo nextest run -p zenith_menus -p zenith_deploy -p zenith_local_history -p zenith_problems -p zenith_search -p zenith_rails -p zenith -p workspace --no-fail-fast`; `cargo clippy -p <touched> --all-targets -- -D warnings`; upstream budget `git diff --stat <base>..HEAD -- . ':!crates/zenith*'`.
- Bundle: `script/bundle-mac -i` with the env (≈ 17 min). Merge: `git checkout zenith && git merge --ff-only <branch>`.
