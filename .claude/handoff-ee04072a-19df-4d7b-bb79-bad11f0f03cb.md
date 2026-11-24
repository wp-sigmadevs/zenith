## Handoff (deep) — Zenith — 2026-11-24 evening (home machine, `~/GithubProjects/`)

### Done
- Supercharger updated 4.4.8 → 4.4.9 (new hooks load in a NEW session only; adds a Fable model prompt, ask-before-running-downloaded-files, token-store read denials). Autopilot ON (full) until 05:14 on 2026-11-25, this session only.
- `Zenith.app` bundled from `2af98edadc` and installed (≈ 17 min, exit 1 at the DMG `mv`, app fine). Owner checked it with screenshots: Inter, 40 px title bar, tab padding, Z icons, sticky headers, Tools menu (9 toggles + "IDE Features ›"), editor right-click menu, palette without branding, preview-tab italics all OK. Usages line already shows from the LS code lens (#4 author part still unbuilt). Run/Debug absent from the editor menu on a plain PHP file is by design (`editor_menu.rs:164-167`).
- Plan 44 #1 tab menu merged to fork `zenith` @ `0c561d328a` after 4 Opus rounds (`git log f7e6572648~6..0c561d328a`): 3 `pane.rs` lines + appended block, `zenith_menus/src/tab_menu.rs`, setting `zenith.tab_menu.enabled`.
- Plan 44 #7 PHP dialog merged @ `f7e6572648` after 3 Opus rounds, 0 upstream lines (keymap edit is the fork's own `assets/keymaps/zenith.json`): PhpStorm layout, staged Cancel/Apply/OK, awaited settings write, Tab focus. Both pushed (`zenith` = `origin/zenith`).
- Docs (committed locally, NOT pushed): engineering notes `docs/guides/fork-findings.md` § "Session 2026-11-24 (home)", HANDOFF plan 44 row, this brief (latest docs commit, local); `5c30f10` (removed the old home brief) is already pushed.
- Memory: updated `machines.md` (work needs `DEVELOPER_DIR`, home does not), `zenith-review-process.md` (2026-11-24 evidence: green gate never replaces Opus review).

### In Flight
- Plan 44 #3 + #6 (tab-bar end: ⋮ menu + markdown Code/Split/Preview buttons moved to the tab bar's right end, empty toolbar row hidden) — Sonnet agent building on fork branch `feat/plan44-tabbar-end` (from `zenith` @ `f7e6572648`), no report yet. Check `git -C ~/GithubProjects/zed log --oneline zenith..feat/plan44-tabbar-end`. If the session ended, the agent is gone: judge the branch by its diff, then run the gate and an Opus review.

### Decisions Made
- Owner: one by one, build/fix all of plan 44; same loop per chunk (Sonnet builds → my gate → Opus review → fix rounds → merge `--ff-only` → owner asks push).
- Owner: PHP dialog open questions "as you see fit": folder icon reveals the selected path in Finder; footer `?` is a tooltip saying where settings are stored.
- Close All closes pinned tabs too (`close_pinned: true`, "Close All but Pinned" is separate) — kept, owner not asked.
- Fork pushes: owner said "push" for the fork this session; docs-repo `main` pushes still only on the owner's word.

### What Failed
- Round after round, my gate (check/nextest/clippy) passed while Opus found real bugs: double pane update panic (File History), a dock pane made the active pane, Tab keys never moving focus, failed settings write treated as saved. Stub-based tests hid all four. Keep Opus review non-optional.
- A chained `git rm && git commit -qm` was rejected by the commit hook once; separate calls with `-F <file>` worked.
- Implementer ran `cargo fmt --all` by mistake (11 files reformatted, stashed as `stash@{0}`; `stash@{1}` is older). `git stash drop` is guard-blocked.

### Blockers
- none. Owner action: say "push" for the latest local docs commit (HANDOFF, fork-findings, brief) when ready.

### Worktrees
- none besides the main checkouts (`~/GithubProjects/zenith` on `main`, `~/GithubProjects/zed` on `feat/plan44-tabbar-end`). Fork local branches: `main`, `zenith`, `feat/plan44-tabbar-end`.

### Files Touched
- Fork: `crates/zenith_menus/src/{tab_menu.rs (new),tools.rs,zenith_menus.rs}`, `crates/workspace/src/pane.rs` (+129 appended block, 3 call-site lines), `crates/settings_content/src/zenith.rs`, `assets/settings/default.json`, `crates/zenith_php_tools/src/{php_modal.rs (rewritten),php_config.rs,zenith_php_tools.rs}`, `crates/zenith_external_libraries/src/{add_path.rs,zenith_external_libraries.rs}`, `assets/keymaps/zenith.json` (+10), `Cargo.lock`.
- Docs: `HANDOFF.md` (plan 44 row), `docs/guides/fork-findings.md` (new section), this brief.

### Resume With
Read this brief and `plan/44-phpstorm-parity-round1.md`. Collect the #3+#6 agent's work from `feat/plan44-tabbar-end` (or restart it), run the gate with the env below, send it to Opus (give reviewers "deliver by tool call 25"), merge, then continue plan 44 in order: #4 usages author, #9 Remote Host + Deployment, #11 inspection widget, #18 Find in Files splitter, #17 Zed-isms, menu chunks 2-3, Linux/Windows menus; bundle for the owner after #3/#6.

### Start With
- `/sc-status` — confirm autopilot (until 05:14) and that the 4.4.9 hooks loaded in this new session.

### Measurements
- Gate on `0c561d328a`: check clean; nextest 456 passed / 1 skipped (`zenith_menus workspace settings settings_content zenith`); clippy `-D warnings` clean (`zenith_menus workspace settings_content`).
- Gate on `f7e6572648`: nextest 223 passed (`zenith_php_tools zenith_external_libraries zenith_menus zenith_local_history zenith`); clippy clean; upstream numstat outside `zenith*`: only `assets/keymaps/zenith.json` +10.
- Tab menu: 8 files, +731 at first commit; `pane.rs` +129 final (budget 5 lines outside the appended block, kept at 3). Opus rounds: 4 (NEEDS CHANGES ×3, PASS WITH NOTES). PHP dialog: 3 rounds (NEEDS CHANGES ×2, PASS WITH NOTES).
- Bundle: ≈ 17 min; disk 77 → 67 GiB free after bundle + gates (64 GiB at one point).
- Subagent cost per round ≈ 60-190k tokens implementer, 60-85k reviewer.

### Rejected — do not rebuild
- Manual `Workspace::zenith_activate_pane` (calls `handle_pane_focused`): wrong for dock panes, redundant for centre panes (`activate_item(ix, true, ..)` already activates). Opus round 3.
- Dispatching `git::CopyFilePermalink` / `OpenFilePermalink` / `FileHistory` from the pane: no reachable handler / acts on the active editor. Use `workspace::copy_file_permalink`, `git_ui_core::open_file_history` (deferred).
- `tab_index` alone for dialog keyboard access: base keymap `tab → menu::SelectNext` wins. Use the context keymap block + `window.focus_next/prev`.
- Resolving the tab menu target by captured `ix`: stale when tabs change; use `item_id`.
- FreeModel as a Zenith default / separate AI platform / Supercharger auto-install / minimap off: carried over (see `HANDOFF.md` §3, earlier briefs).

### Dead ends
- none new beyond What Failed.

### Open questions
- Whether tab-menu items act on the clicked tab in the live app (non-active tabs, split panes, terminal/debugger panes): unverified, needs a bundle.
- Whether the PHP dialog looks like `mockups/owner-review-2026-11-23/img-10.png` (48 rem width, muted level text, vendor row colour), whether the `…`/`+` pickers and Finder reveal work, and Tab/arrows inside an open dropdown: unverified.
- Whether the first Tab stop is the level dropdown: unproven (tab index is `pub(crate)` in gpui).
- Real-time `wait_for` in the interpreter-probe test: flake risk judged low by Opus, unverified under load.
- Plan 44 verify list items still open (diagnostic summary API, overlay positioning, editor lease during block render, FTP `PWD`, live `enabled` flags).
- Owner pending: PhpStorm screenshots of PHP Runtime / Analysis / Composer Files tabs (those 3 tabs are NOT built); app checks of earlier features; tag Supercharger releases.

### Reproduce
- Env for every fork cargo run (HOME): `export CARGO_INCREMENTAL=0 DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer`; `df -g ~` ≥ 30 in the same command. WORK machine uses `Xcode-27.2.0.app`.
- Gate: `cargo check -p zenith -p zed`; `cargo nextest run -p zenith_menus -p workspace -p settings -p settings_content -p zenith -p zenith_php_tools -p zenith_external_libraries --no-fail-fast`; `cargo clippy -p <touched> --all-targets -- -D warnings`; upstream budget: `git diff --stat <base>..HEAD -- . ':!crates/zenith*'`.
- Merge: `git -C ~/GithubProjects/zed checkout zenith && git merge --ff-only <branch>`, then `git branch -D <branch>` after `merge-base --is-ancestor`.
- Bundle: `script/bundle-mac -i` with the env (≈ 17 min, exits 1 at the DMG `mv`).
- Brief for #7 (kept for reference): scratchpad `brief-7-php-dialog.md` (session scratchpad, may be gone).
