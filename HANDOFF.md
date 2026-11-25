# Zenith — Handoff (work machine → home machine)

Last updated: 2026-11-22 (work machine, repos under `~/GithubRepos/`; home machine uses `~/GithubProjects/`). Read with `CLAUDE.md` (project rules) and `plan/README.md` (roadmap).

## 1. Set up the home machine

```sh
# Tools
xcode-select -p || echo "install Xcode (see below)"
brew install gh cmake fswatch sccache
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh   # if no rustup
cargo install --locked cargo-nextest bacon cargo-sweep   # plan 17
# sccache for ~/GithubRepos (or ~/GithubProjects) only — not machine-wide:
mkdir -p ~/GithubRepos/.cargo && printf '[build]\nrustc-wrapper = "sccache"\n' > ~/GithubRepos/.cargo/config.toml
gh auth login            # smrafiz (daily) — add wp-sigmadevs too if you need admin tasks
gh auth switch -u smrafiz

# Repos
mkdir -p ~/GithubRepos && cd ~/GithubRepos
git clone https://github.com/wp-sigmadevs/zenith.git
git clone --filter=blob:none https://github.com/wp-sigmadevs/zed.git
git -C zed remote add upstream https://github.com/zed-industries/zed.git
git -C zed switch zenith

# Stock-Zed config layer (plan 03)
zenith/zed-kit/install.sh --dry-run && zenith/zed-kit/install.sh
```

Then merge `zenith/zed-kit/settings.global.jsonc` into `~/.config/zed/settings.json` by hand: PHP `language_servers: ["intelephense","phpactor","..."]`, the twig/dockerfile/make/http extensions, Tailwind `includeLanguages` for php/blade, and `telemetry` off. Claude's Supercharger hook blocks writes to `~/.config`, so you make that edit yourself.

Xcode notes from the work machine:
- The App Store Xcode needs macOS ≥ 26.6. On 26.5, use Xcodes.app (`brew install --cask xcodes`) → Xcode 26.5.0 → Make active.
- Run `sudo` in the real Terminal app, not Claude's `!` prompt (no password prompt there).
- `sudo xcode-select -s /Applications/Xcode-26.5.0.app/Contents/Developer && sudo xcodebuild -license accept`
- `xcodebuild -downloadComponent MetalToolchain` — required; without it `gpui_apple` fails with "missing Metal Toolchain".
- Need ≥ 80 GB free for Xcode plus Zed's `target/`.

## 2. State

| Area | State |
|---|---|
| Plan (35 docs) + GitHub (32 issues, 6 milestones; README, LICENSE, SECURITY, issue/PR templates) | ✅ `wp-sigmadevs/zenith`; plan 35 PHP toolchain = issue #32 (Phase 3, before 21) |
| Engineer agents (15) + hooks | ✅ `.claude/agents/`, `.claude/hooks/` — modernized, pushed (`81cba24`) |
| 03 config layer (`zed-kit`) | 🟨 installed on both machines (home 2026-11-17: install.sh, WPCS 3.4.1, Phpactor on in `zed-config` `98e70fb`); **not yet verified in a running Zed** |
| Fork | ✅ `wp-sigmadevs/zed` (smrafiz has write). Branches: `zenith` (`0cb9e7432e`: upstream main + rebrand + `.zenith` project dir) · `feat/branding` (`0214f9dbc5`: icon, full rebrand, logo, tagline — merged into `zenith` @ `76f912fa08`) · `feat/rebrand` (`8c4e083700`, now contained in feat/branding) |
| Plan 01 | ✅ run, tests, upstream merge; `script/bundle-mac -i` → `/Applications/Zenith Dev.app` opens (home machine, 2026-11-16) |
| Icon | ✅ `brand/zenith-icon.svg` (layers `background`/`glyph`) + 512/1024 PNGs; swapped into all 8 `crates/zed/resources/app-icon*.png` on `feat/branding` |
| Plan 02 rebrand | ✅ code done, compiled, tests pass, bundle opens — see §2b |
| Plan 32 welcome | 🟨 `feat/welcome` merged into fork `zenith` (`2800023217`, pushed 2026-11-17; check + welcome/palette tests green). In the home app (`feat/look` @ `65c87e35ba`, installed 2026-11-18 00:05). Owner: visual check, remove README notice |
| Plan 33 accounts | ⬜ brief only; Sign In hidden meanwhile |
| Plan 34 Claude Design | 🟨 merged into fork `zenith` (`feat/look` @ `0e96d21d1a` is an ancestor of `zenith`). Shortcut-crash fix `792dfb4795` and board sizes are in `zenith`; never yet installed on the work machine (no `Zenith Dev.app` in `/Applications` on 2026-11-22). Visual check notes: `plan/visual-check-2026-11-19.md`. Owner keeps fonts 16/17/1.8 |
| Home build 2026-11-19 (Xcode 27.2) | ✅ bundle of `feat/look` @ `7d94af7f01` built in 19 m 33 s and runs; Lucide icons (`2b63f7875f`) and `zenith_splash` startup card (`2b0776d98f`) added; upstream synced (`plan/sync-log.md`), `zenith` `a29abb9ed4`, `feat/look` `1f946e7e85`, all pushed. Splash + icons + sync not yet seen in an app until the next bundle. Still to do: Search Everywhere / Recent Files vs PhpStorm shots, title-bar centred search + ⌄, project panel selection style, status bar order |
| Plan 21 inspections | 🟨 fork `feat/look` @ `c52e3978da`: on save, changed files, folder, current file, project, PHPCBF fix, suppress (⌘.), settings (plan 21 §Progress); 33 tests. Home app = `9c2cf04a91` (no suppress, no file/project scope) |
| Fork branches 2026-11-20 (local, unpushed) | 🟨 `feat/local-history` @ `511c689f8e` (plan 05 C1–C5, from `8bcf87ad77`; unpushed unless pushed later) and `~/GithubProjects/zed-p21` `feat/inspections-baseline` @ `1323a2968a` (plan 21 B0–B2). Open: `cargo check -p zenith` and running-app checks for plan 05 C3–C5 and plan 21 B2; `test_zenith_panel_chrome` fails on `feat/look` from `8bcf87ad77` (action `zenith_templates::NewFromTemplate` not registered in the `project_panel` test binary); push/merge decision pending |
| External libraries merge 2026-11-21 | 🟨 fork `zenith` @ `7ef1dc7da2` (merge of `feat/external-libraries` @ `3ec7baecab`, pushed; `zed-extlib` worktree removed, branch kept). Reviewed (code + security, 2 rounds), fixes landed. Wired: only `zenith_external_libraries` (plan 39; setting `zenith.external_libraries.enabled`). UNWIRED workspace members (no init/umbrella feature): `zenith_http` (08), `zenith_refactor` (09), `zenith_postfix` (26), `zenith_wordpress` (19), `zenith_laravel` (25), `zenith_nextjs` (40). Not built: plan 39 M3, hook 5 (drag-and-drop). Not checked in a running app |
| Fork `zenith` 2026-11-22 | 🟨 `d58e761135` (pushed; working branch, checkout switched from `feat/look`). Since 11-20: plan 05 local history C1–C5, plan 21 inspections baseline, external libraries + rework, WordPress/Laravel/Next.js panels, `zenith_http`/`zenith_postfix`/`zenith_refactor` wired, PHPantom default + global config writer (plans 41/42; stubs write dropped in `d58e761135`), stable channel (`Zenith.app`), seeded default user settings. Not built or run on this machine; audit 2026-11-22 in `plan/audit-2026-11-22.md` |
| Fork 2026-11-22 (evening) | 🟨 `zenith` @ `8ef52d743d`: plan 23 M1 + review fixes, 3 External Libraries tests (owner kept 3 of 5), live template tab stops/variables (plan 26). `integrate/batch-b` @ `205d3c3827` (tests + `cargo check -p zenith` + clippy pass; not built into an app): route autocomplete (25/40), tab icon padding, HTTP gutter ▶ + session history + Basic/Bearer + `< file` + cURL import (08), single External Libraries node (39), Find in Files colours + editable preview, bottom navigation bar `zenith_navbar`, PhpStorm editor look (thin indent guides, literal-only parameter hint pills, amber 16 px bulb), settings independence (`.zenith/settings.json` replaces `.zed/`, Zenith-only PHPantom `XDG_CONFIG_HOME`, instance port base 47737), own keychain entry `credentials_url = https://zed.dev/zenith`. Snapshot: `plan/status-2026-11-22.md` |
| Fork 2026-11-22 (night, home) | ✅ batch B fixed + merged: 14 failing tests on `integrate/batch-b` `13c322d73f` (welcome page request, code-lens Open in Tab, usages test settings, stale inline-diagnostics test) fixed in `5e13493d92` `6e2204e036` `5d12e161da`; `zenith` ff + pushed. Upstream sync `d31d1074a0` (35 commits) merged `66bdccbd97`, pushed (`plan/sync-log.md`). Gate: `cargo check -p zed`, nextest zenith_* 672/672, clippy clean. `Zenith.app` bundled 23:10 (20 m 32 s) from `66bdccbd97`, launches; not yet checked by the owner |
| Fork 2026-11-23 (home) | ✅ `zenith` @ `16a24c9fa6`: plan 37 M1a (`zenith_deploy`), plan 39 scratches node, plan 39 PHP config M1 (the scratches/M1a review findings below are now fixed) |
| Fork 2026-11-23 (work, evening) | 🟨 pushed WITHOUT running tests or the gate (owner's call; only `cargo check -p zenith`). Merged: scratches fixes + "Scratches" label, deploy M1b (dialog + Remote Host panel, FTP/SFTP hardening, target-bound Keychain secrets), PHP modal + config fixes, HTTP history masking, `toolbar.breadcrumbs` default off, `zenith.navbar.enabled`. Opus-reviewed. Details and open items: `docs/guides/fork-findings.md` § "Review round (2026-11-23, work machine)". FIRST next session: run the full gate (`cargo nextest` on all `zenith_*` + clippy), then fix the HTTP history userinfo gap (`strip_url_userinfo`), then the open deploy items |
| Fork 2026-11-23 (home, night) | ✅ gate on merged tree: 976/976 zenith_* + project_panel/scratches, clippy -D warnings, `cargo check -p zenith`. Fixed: zenith_templates duplicate-action test panic (18 fails), HTTP history userinfo gap (every URL spelling; templates keep `{{var}}`), owner-approved masking names, `find_php` retry for all callers. Opus-reviewed. `zenith` @ `e02f05c5f9` (local, ahead 4) |
| Fork 2026-11-23 (home, late) | ✅ `zenith` @ `503fca5ea7` (local, ahead 4): cargo audit bumps (22 → 17), deploy follow-ups (8 items + race fixes, 3 Opus rounds, 84 tests). Plan 43 AI Terminal approved (offer-not-auto Supercharger, agy + gemini, tag + sha256 pin); plan 43 ON HOLD (owner) |
| Plan 44 (owner review 2026-11-23, 18 items; `plan/44-phpstorm-parity-round1.md`) 2026-11-24, work | 🟨 DONE, Opus-reviewed, gated, merged and pushed (`zenith` @ `2af98edadc`; branches deleted): #15 title bar 40 px, #16 tab padding (`Base12`), #13 navbar font, #8 "Scratches and Consoles", #10 Agent Review icon; 17b Z-logo icons, 17c Inter v4.1 (UI font size stays 16), 17d edit prediction provider none, 17e palette branding hidden (fork-wide, settings observer), #5 sticky headers ON by default with the upstream panic fixed in `autoscroll.rs` (anchor conversion, ~16 lines carried in the fork); #14 `zenith_menus` chunk 1 (PhpStorm menu order, Tools with 20 check-marked toggles, one submenu level, restart notice, Help bug-report/repo/email items dropped); #2 editor right-click menu (`zenith.editor_menu.enabled`). 2026-11-24 home: #1 tab menu merged `zenith` @ `0c561d328a` (4 Opus rounds; 3 `pane.rs` lines + appended block), #7 PHP dialog merged @ `f7e6572648` (3 rounds, 0 upstream lines), both pushed, neither seen in the app; owner bundle check of steps 1-5a passed (screenshots). 2026-11-25 home: #3 + #6 tab-bar end merged `zenith` @ `7f1980288a` (`zenith_rails::tab_bar_end` registry + visibility predicates, 3 upstream source lines + 4-line `#[path]` test hook; 3 rounds), #18 Find in Files splitter merged @ `217d6dfa88` (0 upstream lines; Opus ×2 NEEDS CHANGES, round 3 fix not re-reviewed), both pushed, neither seen in the app. 2026-11-25 work: #11 inspection widget (`zenith_problems`, tab-bar end, 0 upstream source lines) + #18 splitter follow-ups (keyboard/aria, Replace row) merged locally on fork `zenith` @ `ecbee8f25d`, unpushed, not seen in the app. 2026-11-25 work, fork worktree branch `feat/plan44-screenshots` (not merged, not pushed, not seen in the app): #4a tab-aware lens indent (PR candidate) + #4b usages style/author hooks; #17-R1 `rebrand_text` and bundled-text rebrand hooks; G1 pinned tabs one row; G2 end-of-line blame left alone. Plan 37 M4a C1 transport merged on `feat/plan37-m4a-edit-remote` @ `0cffe2ae20` (not on `zenith`); C2-C4 unbuilt. PENDING (unbuilt): #4 usages author part (built on the unmerged branch above), #9 Remote Host + Deployment, #12 preview-tab italic is OK (settled), #17 rest of Zed-isms, menu chunks 2-3 (Code/Refactor/Git contents, live-vs-restart flags), Linux/Windows menu refresh. NOT SEEN IN THE APP: bundle postponed (owner); needs `DEVELOPER_DIR` (see fork-findings § Session 2026-11-24) |
| Fork branches in progress 2026-11-22 | ✅ all merged into `zenith` (checked 2026-11-23: `9d09c9e6dd` todo filters, `3da2b49dd3` welcome, `da0a6707c1` scratches run, `35648a90f2` run widget, `297f274e5e` templates M1); no Zenith branches left on origin |
| Plan 42 M0 | ✅ PHPantom `main` @ `b759b41da6` built (Rust 1.98.1, `--ignore-rust-version`), installed `~/.local/share/zenith/tools/phpantom/b759b41da6/phpantom_lsp` + `current`; SHA-256 in `docs/guides/fork-findings.md`. Security review: no new network/process/write sites. Stdio: `add_action` → `wp-includes/plugin.php:441` |
| Owner settings 2026-11-22 | `~/.config/zenith/{settings,keymap}.json` now point at `zed-config/config/zenith-settings.json` / `zenith-keymap.json` (were the same files as Zed's) |
| `.zenith` project dir | ✅ `feat/zenith-dir` merged into `zenith` (`0cb9e7432e`). New settings/tasks/debug go to `.zenith/`; `.zed/` still read (settings merged, `.zenith` wins). On `integrate/batch-b` (`4c4cf69555`) `.zenith/settings.json` replaces `.zed/`. Not yet checked in running app |
| UI mockups | ✅ `docs/ui-mockups` merged into `main` (`219d2e7`): `mockups/zenith-v1.html` (all features on one screen), `mockups/zenith-v2.html` = target look (Editing / Debugging / Agent review scenes, orange = agents only), Claude Design export (`5e0d712`); default Driftwood + Archipelago Icons (plan 14), being built in plan 34 |
| First build `cargo build -p zed` | ✅ on work machine (debug, after installing the Metal Toolchain; first build ≈ 1 h, incremental ≈ 2 min; target/ ≈ 25 GB) |
| `cargo test -p workspace` | ✅ 307 passed (work machine) |
| Toolchain | Rust 1.98.1 (pinned by repo), Xcode 26.5 (work machine now also `/Applications/Xcode-27.2.0.app`; `xcode-select` still points at CommandLineTools — set `DEVELOPER_DIR`, see fork-findings), cmake 4.5 |

Installed on **work** machine (home ran `zed-kit/install.sh` 2026-11-17: zed-php-fmt link + phpactor.json; WPCS 3.4.1 in global Composer (phpcs pinned to 3.13.6 — WPCS has no PHPCS 4 support; Homebrew phpcs 4.0.4 also present, `~/.zshrc` puts `~/.composer/vendor/bin` first); no Xdebug; home Zed settings = symlink to `~/GithubProjects/zed-config`, Phpactor off via `"!phpactor"` since its first commit): `~/.local/bin/zed-php-fmt` → repo symlink; `~/.config/phpactor/phpactor.json`; Zed settings backups `~/.config/zed/settings.json.backup-20261115-*`.
Machine facts: PHP 8.5, Composer 2.10, Node 22, phpcs + WPCS in `~/.composer/vendor/bin`, Valet, fswatch; no Xdebug, no Intelephense licence. Home machine: Xcode 26.5 + Metal Toolchain, cmake.

Open issues (plan 03):

- Verify 03 in Zed: go-to-def/rename, Phpactor code action, PHPCS (WP) / PHPStan (Laravel) inline, Pint on save, no duplicate completions, per-project Intelephense stubs applied, Phpactor auto-download.
- Xdebug not loaded (`install.sh --with-xdebug` or Herd/Valet PHP).
- `install.sh --dry-run` labels real checks as `dry` too (cosmetic).

## 2b. Rebrand (plan 02) — status

Owner decisions: **full rebrand** ("everything"), **telemetry/crash/auto-update off**, settings **copied once** (done).

`feat/branding` commits on top of the icon commit:
- `9359dfe882` core: `paths.rs` APP_NAME "Zenith" (+ removed main.rs bin-name assert), release_channel display_name + app_id → `io.github.wp-sigmadevs.Zenith*`, URL scheme `zenith://` / `zenith-cli://` (+ Cargo.toml osx_url_schemes), CLI → `/usr/local/bin/zenith`, auto-update off via `.cargo/config.toml` `ZED_UPDATE_EXPLANATION`, telemetry defaults off, DMG `Zenith-<arch>.dmg`, plist strings.
- `04f99cf8a4` + `7ab5ccdbaa`: user-visible "Zed" → "Zenith" (UI strings + settings doc comments). Rule: app/editor → Zenith; Zed's services/company (zed.dev account, Zed AI/Pro, Zed Agent, edit-prediction data, billing, extension registry, Zed Industries) stay "Zed". Kept on purpose: identifiers, `ZED_*` env, `.zed/`, `.zed_server`, zed.dev URLs, HTTP User-Agent, MCP/DAP client names, font/icon/theme names ("Zed Plex/Mono", "Zed Icons"), base keymap "Zed", internal `zed:///` mention URIs and `zed://schemas/` (persisted/internal), Windows-only code.
- `8c4e083700` fix: telemetry test compiled after importing `BorrowAppContext`.
- `057ee02022` logo: `assets/images/zed_logo.svg` + Zed half of `zed_x_copilot.svg` → monochrome Zenith glyph (peak + sun).
- `9e995fb586`, `0214f9dbc5` tagline "IDE depth. Editor speed." (onboarding, welcome, snap summary).

Verified (home machine): `cargo check -p zed` ✅; tests ✅ 785 passed / 0 failed (release_channel, paths, cli, workspace, client, agent_skills, terminal, context_server, zed, title_bar, oauth_callback_server); bundle opens with Zenith name/icon.

Left: Windows instance names still `Zed-Editor-*` (only matters on Windows). Fork README `> [!IMPORTANT]` notice — owner removes it by hand before merging into `zenith`.

Data: on the work machine `~/.config/zenith` and `~/Library/Application Support/Zenith` were copied from Zed (db via `sqlite3 .backup`). On the home machine Zenith was launched first, so it has a fresh data dir; copy Zed's db over it (Zenith quit) if history is wanted.

Name risk: pending USPTO "ZENITH" word mark (Zenith IOS Manager LLC, filed Jun 2025) — goods/services unchecked. Check before any public release.

## 3. Owner decisions (2026-11-23, all approved)

1. ✅ Commit prefix `feat(<crate>):` (plans 02/16 updated).
2. ✅ `<example>` blocks dropped from agent descriptions.
3. ✅ Scratches kept (plan 04/39 node is built).
4. ✅ Plan 22 shrunk to tasks.json recipes + a guide (lead-engineer audit, no fork code).
5. ✅ (`ac604bb44d`) HTTP history masking: add `ssn`, `card_number`, `cvv`, `cvc`, `otp`, `totp`, `mfa_code`, `pin`, `secrets`, `tokens`, `refresh`, `signing_key`, `write_key`, `AccountKey`; not bare `access`..
6. Collab + invisible worktrees: document only (owner works solo); no upstream hook.
7. ✅ Deleted the 13 merged fork branches on origin (commits stay in `zenith`).
8. `settings_ui` entries for `zenith.*` flags: deferred, add as one batch later.
9. ✅ (`e9e8409070`) `find_php` 10 s retry moves into `find_php` itself (all callers).
10. `project_panel` 9 hook lines: accepted exception to plan 02's budget of 5.
11. "Scratches > Scratches" label: leave.
12. JetBrains settings import (plan 31): after the gate and bundle check.

## 4. Next steps (in order)

Owner decisions 2026-11-22: plan 42 approved; plans 14/34 fork-only parts; batch order A → B → E → C → D; editor look = PhpStorm; delete worktrees right after merge.

00. ✅ Batch B merged + upstream synced + bundled (home, 2026-11-22 night). Owner: quit the old Zenith, relaunch, check ⇧⇧/⌘E/⌘⇧6/⌘⇧F, welcome Projects/New Project, lens Open in Tab. Then batch E → C → D from the in-progress branches above; remove each worktree right after its merge.
0. **Only when the owner asks:** `cargo check -p zed` + zenith crate tests, then bundle current `zenith` (stable channel ⇒ `Zenith.app`; ~2.5 h without warm sccache; keep ≥ 30 GiB free, 56 GiB late 2026-11-22). Then: confirm ⇧⇧/⌘O/⌘E/⌘⇧E no longer quit; screenshot vs `mockups/claude-design/Main.dc.html`, then tool windows + Search Everywhere (not yet checked). Remaining gaps + owner's settings edit (PHP servers, WP stubs): `plan/visual-check-2026-11-19.md`. Do not restore the backup app (owner).
0b. ✅ `feat/look` is in `zenith`. Owner: remove the fork README notice.
0c. Plan 27 TODO window ✅ in code (`294b4c570a`, plan 27 §Progress; not seen in the app). Done in fork (unpushed): plan 21 B0–B2, plan 05 C1–C3. Next: plan 05 C4/C5, plan 21 B3, running-app checks. Board gaps waiting on plans: plan 34 "Main board check" table.
0d. ✅ 2026-11-21 wired `zenith_http`, `zenith_refactor`, `zenith_postfix`, `zenith_wordpress`, `zenith_laravel`, `zenith_nextjs` (`zenith_nextjs` merged as in-progress/unreviewed, `d94951dfb3`). Still open from the merge review: `project_panel` 9 hook lines + 475-line module: owner accepted (§3.10). Known gaps: plan 39 M3 and hook 5 not built; `apply_to_disk` not transactional; `read_regular` duplicated in laravel/nextjs (unify with the shared fn in `zenith_php_tools`); `zenith_row_kind` per-frame cost; redirect check misses hostnames resolving to loopback; wordpress scans only the first 4 KiB of a line; `zenith_menu` hook untested; fish quoting untested (fish not installed); a future wordpress caller must use a bounded read before `index_source`.
0a. Owner to decide: JetBrains settings import first slice (plan 31) on the welcome Customize page — detect `~/Library/Application Support/JetBrains/<Product><ver>`, import keymap base + editor font/size/tabs/soft wrap/theme; hide or redirect "get merch"/"open docs".
1. ✅ 2026-11-16: notice removed, `feat/branding` merged into `zenith` (`76f912fa08`), pushed.
2. ✅ Commit prefix `feat(<crate>):` decided 2026-11-23 (§3.1); close plan 02.
3. ✅ Plan 17 (2026-11-19): sccache, nextest, bacon, cargo-sweep, line-tables-only; `plan/build-log.md`.
4. lead-engineer re-checks the agents' Zed API facts against the real fork source (8 items still marked *verify*).
5. Verify plan 03 in Zed (checklist in `zed-kit/README.md`) → mark ✅, close its issue.
6. Plan 15 `zenith_core` → Phase 1 (04 scratches?, 14 toolbar, 05 local history…).

## 5. Gotchas

- Commits must be conventional (`docs:`, `feat(x):`, `fix:`, `chore:`); a hook rejects others.
- Claude's auto-mode may block `git push` to a public repo unless you ask for it explicitly in chat.
- Supercharger blocks writes under `~/.config/` and creating `.claude/hooks/` from Claude; do those yourself.
- Project agents load only in sessions started inside `~/GithubRepos/zenith`. Start Claude there, or symlink `.claude/agents` and `.claude/hooks` into the fork.
- Admin on a personal-account repo can't be granted to collaborators; do admin tasks as `wp-sigmadevs` (`gh auth switch -u wp-sigmadevs`).

## 5b. Resume prompt for Claude

```
cd ~/GithubProjects/zenith && claude   # work machine: ~/GithubRepos/zenith
> Read HANDOFF.md, CLAUDE.md and .claude/handoff-ee04072a-19df-4d7b-bb79-bad11f0f03cb.md (the current brief). Never build/bundle unless the owner says so in that message; ask about §4 step 0.
```
