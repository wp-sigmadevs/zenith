## Handoff (deep) — Zenith — 2026-11-24 (home machine, `~/GithubProjects/`)

### Done (2026-11-23/24, all merged + pushed)
- Gate on merged `zenith`: 976/976 zenith_* + project_panel/scratches, clippy -D warnings, `cargo check -p zenith`.
- Fixes: zenith_templates duplicate-action test panic; HTTP history userinfo stripped for every URL spelling (templates keep `{{var}}`); owner-approved masking names; `find_php` retry for all callers; cargo audit bumps (22 → 17); deploy follow-ups (8 items + save-race fixes, 3 Opus rounds, 84 tests).
- Owner decisions §3 (12) recorded; 13 merged origin branches deleted; plan 22 → recipes; plan 43 AI Terminal planned then ON HOLD; stale plan rows fixed; release notes section in `docs/guides/release-compliance.md`.
- `Zenith.app` bundled from `zenith` @ `503fca5ea7` (≈ 17 min warm) and reviewed by the owner → **plan 44** (PhpStorm parity round 1, 18 items) written and approved: all decisions as recommended except minimap stays ON.

### State
- Fork `zenith` @ `503fca5ea7` = origin. Docs `main` = origin. No branches, worktrees, agents or builds running.
- Disk ≈ 70 GiB free after the bundle.

### Start with
- Read `plan/44-phpstorm-parity-round1.md` (summary table, build order, D1–D15) and `mockups/owner-review-2026-11-23/README.md` (images).
- Owner said "there are a lot more" UI issues: expect round 2.

### Next (plan 44 build order; Sonnet builds, Opus reviews, tests proven to fail without the fix, bundle check before ✅)
1. Quick wins in one `ui` rebuild: #10 Agent Review icon → `file_diff`; #13 navbar font follows UI size; #8 "Scratches and Consoles" › "Scratches", no path suffix; #16 tab left padding 12 px; #15 title bar 40 px + traffic lights y 12.
2. #17b swap Zed-logo SVGs for Lucide glyphs; hide edit-prediction button without provider; hide "get merch"/"open docs".
3. #5 sticky_scroll on (pin old value in upstream editor tests); #12 check italic preview + preview from ⇧⇧/file finder.
4. #14 `zenith_menus`: PhpStorm menu bar + Tools with ☑ per feature. Also D2: UI font → Inter 13.
5. #2 editor menu (`set_custom_context_menu`), #1 tab menu (pane.rs one call site).
6. #3 + #6 tab-bar end (⋮, markdown switcher).
7. #18 Find in Files splitter. 8. #4 usages line (4a upstream-PR indent fix, 4b style hook). 9. #7 PHP dialog. 10. #9 Remote Host + Deployment. 11. #11 inspection widget + browser (URL from deployment web path).

### Before each chunk
- Check its *verify* items (list in plan 44) against the fork source first; chunk briefs are not written yet — the implementer gets the plan 44 section + this list.
- `df -h ~` ≥ 30 GiB in the same command as cargo; `git -C`; no parallel builds on one target dir.

### Waiting on owner
- Screenshots of PhpStorm PHP dialog tabs PHP Runtime / Analysis / Composer Files (plan 44 #7).
- App checks of earlier merged features (Deployment, PHP modal, local history, TODO, welcome, plan 23 review queue, run widget, WP/Laravel/Next.js panels).
- Tag Supercharger releases (plan 43, on hold).

### Known risks
- Two load-timing flakes in full parallel nextest: `zenith_deploy sftp::tests::dropping_the_operation_kills_the_sftp_child`, `zenith_inspections tests::test_a_single_save_looks_up_the_base_beside_the_tools` (pass alone).
- Deploy: refused outdated dialog loses unsaved edits; an unanswered Keychain prompt blocks saves in all windows (accepted).
- HTTP history: a scheme colon inside a variable (`{{proto}}//user:pw@host`) still stores the password.

### Rejected — do not rebuild
- Separate "universal AI platform" product; bundling FreeModel (unidentified reseller).
- Supercharger auto-install (offer only); plan 43 work while on hold.
