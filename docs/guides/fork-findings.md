# Fork engineering findings

Facts learned while building Zenith in the fork (`wp-sigmadevs/zed`). Moved verbatim from `CLAUDE.md` §Findings on 2026-11-18; add new findings here under the matching heading, not in `CLAUDE.md`.

## Build, bundle and disk

- Release builds: `script/bundle-mac -i` (dev channel → `Zenith Dev.app`); `-d` debug. Unsigned → ad-hoc codesign, universal links off. `-i` exits 1 *after* "Installed application bundle" (upstream script then mv-s the moved app for the DMG) — app is fine. Build regenerates `assets/licenses.md` (stays clean).
- Timings (home, first run): `cargo check -p zed` 11m 13s; bundle zed binaries 11m 10s + remote_server 7m 49s. Plan 17 targets these.
- Disk/time (work machine, 2026-11-16): `target/` reached 73–80 GiB; `cargo clean` freed 80.1 GiB. Full release bundle from clean 115m 11s; full `./script/clippy` after it 8m 45s; incremental bundle after small UI edits ≈ 51m (35m + 16m). Never `cargo clean`/delete `target/` while a build or clippy runs — it killed clippy (`os error 2`).
- Disk (work machine, 2026-11-17): `cargo test -p zed` ≈ +18 GiB; `target/debug/incremental` grows to ≈ 26 GiB (`rm -r` is safe when nothing builds); `./script/clippy` builds the release profile. After big test runs `cargo clean -p <crates>`. Keep ≥ 30 GiB free.
- Disk (home, 2026-11-16): target/ grew 93 → ~120 GiB from one session of per-crate `cargo test` + clippy + one release bundle; disk hit 0 mid-run (ENOSPC breaks Bash/Edit entirely). `cargo clean` freed 135.8 GiB. Check `df -h ~` before test/bundle runs; keep ≥ 30 GiB.
- Per-crate gates are cheap after a warm build: `cargo check` 8 crates ≈ 52 s; `cargo test -p project --test integration <filter>` ≈ 1 min; incremental release bundle 12 min.
- Release bundle can fail on `webrtc-sys` build: it downloads `webrtc-mac-arm64-release.zip` (255 MB) from GitHub releases with no retry; on a flaky line it times out (2026-11-17 home). Fix: `curl -L -C - …` until complete, `unzip -t`, unzip, then `LK_CUSTOM_WEBRTC=<dir>/mac-arm64-release ./script/bundle-mac -i` (`webrtc-sys/build/src/lib.rs` `custom_dir()` skips the download).
- Release bundle 2026-11-18 (work machine, after Rust-file changes in ~10 crates): 39 → 25 GiB free while compiling; `project` alone compiled > 53 min in release; not finished when the session ended (owner shut down).
- Disk (home, 2026-11-18/19): one session of per-crate tests on editor/zed/workspace took `target/` to 98 GiB (debug 72, incremental 10–38). `cargo clean --profile dev` freed 74.8 GiB and `--profile release` (clippy) 7.2 GiB; keeping `target/aarch64-apple-darwin` (19 GiB) keeps the next bundle incremental.

## Rebrand and branding

- Rebrand choke points: `crates/paths/src/paths.rs` APP_NAME (+ assert in zed main.rs that APP_NAME_LOWERCASE == bin name), `release_channel` display_name/app_id, `client.rs` ZED_URL_SCHEME + open_listener literals, `install_cli_binary.rs` CLI path, auto-update off via build env `ZED_UPDATE_EXPLANATION`, crash upload off when `ZED_MINIDUMP_ENDPOINT` unset, telemetry defaults in `assets/settings/default.json`. Keychain creds keyed by server URL (keep `zed.dev`).
- Fork's own `CLAUDE.md` hard rule: any source edit ⇒ prepend `> [!IMPORTANT]` + review line to README.md; only the human removes it.
- Rebrand keep-as-"Zed" list (services, User-Agent, MCP/DAP client names, fonts/icons/themes, base keymap "Zed", internal `zed:///` mention + `zed://schemas/` URIs, Windows-only names): HANDOFF.md §2b. Logo = contents of `assets/images/zed_logo.svg` + `zed_x_copilot.svg` (no code hook).
- No-Zed-branding rule (owner, 2026-11-16): nothing user-visible says "Zed". Cheapest levers: `command_palette::humanize_action_name` shows `zed::` as `zenith:` (display only; ids stay `zed::` so keymaps work; also feeds which-key); `title_bar.show_sign_in` default false; own copies in `zenith_welcome` instead of upstream edits. Still Zed-pointing: "zenith: get merch", "zenith: open docs" (zed.dev).

## `.zenith` project dir

- `.zenith` project dir (fork `823272e9d0`): choke point `crates/paths/src/paths.rs` (`local_settings_folder_name` = `.zenith`; `legacy_*` = `.zed`; `is_local_settings_folder_name`). Settings for both folders share one key (parent dir) in `SettingsStore`, so `project_settings.rs::load_merged_local_settings` loads both and merges (`util::merge_json_value_into`, `.zenith` wins). Tasks/debug key by the folder itself ⇒ both listed. Other touch points: worktree always-scan, `agent/src/tools/tool_permissions.rs::is_local_settings_component` (security: both folders prompt), task_inventory `.vscode` hiding, debugger new_process_modal, json_schema_store, security/alert modal text. ~10 upstream files — expect merge conflicts there.

## Upstream files, settings and keymap

- Zenith keymap: `assets/keymaps/zenith.json` loads after the base keymap (`zed.rs` `load_default_keymap`, `settings::ZENITH_KEYMAP_PATH`), so it wins over JetBrains bindings. Loading `.unwrap()`s: every action named there must be linked into the app, and a test that loads it must link the action's crate (`KeymapFile::load_asset` fails on unknown actions). `"secondary-…"` = cmd on macOS, ctrl elsewhere. Don't edit upstream default keymaps.
- Optional actions without a crate dependency: `cx.build_action("debugger::Start", None).ok()`.
- Changing `assets/settings/default.json` breaks upstream tests that assume the old default; pin the old value inside those tests (done for project_panel `test_focus_follows_mouse_into_blank_area`, git_ui `test_history_tab_pane_navigation_focuses_rendered_panel`). Run the touched crates' tests after any default change.
- Upstream file edits that can't be one line: append a block at end of file (e.g. `command_palette.rs` shared-history fns) — modified upstream lines conflict on sync, an appended block rarely does.
- An action shown by an upstream menu but handled in a zenith crate lives in `zed_actions` (appended `pub mod zenith_inspections`), so the upstream crate needs no dependency on ours.
- Zenith reads `~/.config/zenith/settings.json`, not Zed's `~/.config/zed/settings.json`; a setting the owner has in Zed (e.g. `project_panel.folder_indicator: "both"`) is missing in Zenith unless it is a Zenith default or copied over (2026-11-18).
- Every keymap loaded in `zed.rs` `load_default_keymap` must go through `filter_disabled_ai_bindings`, or `test_disable_ai_filters_keybindings` fails once it binds an AI action.
- Changing editor defaults broke upstream editor tests: indent-guide colouring (`setup_indent_guides_editor`) and the 1.8 line height (`code_lens::test_code_lens_resolve_only_visible`); both now pin the old values. Two `zed` tests already failed before that (zenith action namespaces, project panel docked left) and were updated (2026-11-18).
- Zenith chrome switches: `workspace::IslandsActive` (set by `zenith_rails`) gates the tab accent line, root location, picker 🔍/`esc` field, Go to Line dialog; `workspace::dock::RailsActive` gates the tool-window headers. Upstream crates key off these instead of depending on zenith crates.

- Work machine 2026-11-19 (plan 17, details `plan/build-log.md`): release bundle after `settings_content` + `editor` edits 162 m 14 s; after a `zenith_*`-only change 47 m 09 s. `crates/settings` RustEmbeds `assets/settings/*` and `assets/keymaps/*`, so editing `default.json` or `zenith.json` recompiles `settings` and ~everything above it in release (~2.5 h); `workspace`, `editor`, `ui`, `project*`, `theme` edits cost the same. Themes (`assets/themes`) go through the `assets` crate (`editor`, `zed`, `zenith_look`, …).
- sccache via `~/GithubRepos/.cargo/config.toml` (`rustc-wrapper`); caches third-party crates only. Its server idles out after 600 s mid-build: start it with `SCCACHE_IDLE_TIMEOUT=0 sccache --start-server`. Never put that in Cargo `[env]` — any `[env]`/profile/rustflags change invalidates every crate (cost one forced full rebuild).
- Stopping a bundle mid-crate leaves that crate dirty; the next run recompiles it fully.

## GPUI UI

- `ui::Button::full_width()` centers its label; for left-aligned nav drop it and let the column stretch.
- New `IconName` variant needs `assets/icons/<snake>.svg`; `icons` tests fail on a missing or dangling svg.
- Title bar (plan 34): upstream holds sections in `ArrayVec<_, 5>` (`crates/title_bar/src/title_bar.rs` ~257); a 6th push panics `CapacityError` when the onboarding banner shows. Add Zenith UI as ONE section (`zenith_title_bar::middle`).
- Picker: `render_header` draws only when there are matches, below the query editor. For chrome above the search box wrap the picker and build it with `.embedded()`; the wrapper is the `ModalView`.
- gpui keymap precedence (`crates/gpui/src/keymap.rs` ~216): deepest matching context first, then later-loaded binding. `"SearchEverywhere > Editor"` in `zenith.json` beats the picker's `tab: menu::SelectNext` and `editor::Tab`; a user keymap still overrides.
- `workspace::StatusItemView` needs `hide_setting` (return `None` when there is no setting). Status items read live state at render time instead of caching it, so settings changes show without a subscription.

- Never read an entity that is mid-update: `cx.entity().read(cx)` inside `observe_new` (startup panic, `zenith_todo` `1e536b0b39`), or calling `panel.icon()` / `enabled()` inside a `Workspace` action — the terminal panel's `icon` reads the workspace (every Search Everywhere shortcut quit the app, `792dfb4795`). Pass the value in, or `window.defer`. Test with a real workspace + a panel that reads it.
- Release panics don't reach `Zenith.log` and leave no crash report; the app just exits. Run `"/Applications/Zenith Dev.app/Contents/MacOS/zed"` directly with stderr to a file and `RUST_BACKTRACE=1` to see the panic.
- Upstream `IconButton` sizes are fixed (`ButtonSize` 32/28/22/18/16 px); a 30 px rail button needs a custom element.

## Testing

- gpui tests: `cx.update_global::<T, _>` needs `use gpui::BorrowAppContext as _`.
- Welcome screen (plan 32): `workspace::welcome::WelcomeOverride` global (fn ptr → `Option<AnyView>`) replaces upstream page; `zenith::show_onboarding_view` swaps onboarding in `main.rs`/`open_listener.rs`. Tests need `editor::init`, `LoadThemes::All(Box::new(assets::Assets))`, `Client` + `Fs` globals, and `AppState::test` *before* re-init (it resets themes). Never `read` the Workspace inside its own update — read `fs` in the spawned task.
- Flaky upstream test: `agent_ui` `test_migrate_thread_remote_connections_backfills_from_workspace_db` failed once under parallel load, passed 5 reruns. Suspect the shared test KVP DB; not ours.
- Agent sensitive-path tests (`edit_file_tool.rs` `expect_authorization().await`) **hang forever** instead of failing when the prompt doesn't fire — kill after a few minutes, a hang = fail.
- Fake LSP workspace symbols in a crate test: `language_registry.register_fake_lsp(..)` + `open_local_buffer_with_lsp` + `set_request_handler::<lsp::WorkspaceSymbolRequest,_,_>`; `LanguageConfig.matcher` needs `.into()` (Arc). Dev-deps: `language`/`lsp` test-support, `futures`.
- `zenith_title_bar` tests need `workspace` test-support in dev-deps (they failed to build on HEAD before `9bdf1df19b`: `RemoteConnectionOptions::Mock` non-exhaustive).
- Zed does not scan inside git-ignored folders (`vendor/`), so a FakeFs test with an ignored folder can't tell `include_ignored` true from false; use an ignored *file* in a scanned folder (`*.cache.php`).
- Crates depending on `project_panel` need `remote_connection` with `test-support` in dev-deps (`RemoteConnectionOptions::Mock` non-exhaustive, E0004).
- `SecurityModal::new` (and anything building `ui_input::InputField`) panics in `workspace` tests: the erased editor factory is set only when `editor` initialises. Test the logic as a free function instead (`security_modal.rs` `has_legacy_settings`).
- Dev/test builds read `assets/` from the checkout at runtime (`util::fs_embed!`), so swapping `default.json` changes test behaviour without a rebuild: handy to check whether a failure predates a defaults change.
- A crate used only as a dev-dependency (e.g. `menu` in `zenith_search`) compiles in tests and clippy but breaks the app build once non-test code uses it. Run `cargo check -p zenith` after every new `use` (2026-11-19, fixed `3ee50bf86b`).
- gpui tests: a view holding an `Editor` only by `WeakEntity` sees it dropped after the closure that made it; keep the editor in a root view (`zenith_look` indent test). `element.layout_as_root` outside a draw panics. `cx.set_global(SettingsStore::test(cx))` is a double borrow: bind the store first. `IconButton` has no `debug_selector`; wrap it in a `div`.
- A sabotage edit that stops the crate compiling proves nothing (2026-11-19: `let _ = (ix, line)` broke type inference). Check the sabotaged run prints `test result: FAILED`, not a compile error.

- `zenith_search`'s keymap test loads the real `zenith.json`; every action it binds must be registered in that test binary. Bindings to sibling crates (e.g. `zenith_todo::ToggleFocus`) need a stub `actions!` in the test module. Run `zenith_search` tests after any `zenith.json` edit.

## Search Everywhere (plan 34)

- Search Everywhere (`zenith_search`, plan 34 step 4): sources return results (`search_files/symbols/actions`), `update_matches` assembles per tab; All = classes, files, other symbols, actions (8 each) and publishes local results before the language server answers. Workspace symbols reuse `project_symbols`'s approach (server filter → fuzzy on `label.filter_text()` → shift positions by `filter_range.start`, in-project first).
- Picker replaces (drops) the previous `update_matches` task synchronously, so a timer at the *start* of the delegate's task is a debounce (symbols: 100 ms). gpui tests: `cx.simulate_input("word")` is one query change — type per key with `run_until_parked()` between, then `cx.executor().advance_clock(..)`.

## Inspections (plan 21)

- Diagnostics without a language server (`zenith_inspections`, plan 21): push through `LspStore::merge_lsp_diagnostics` with an `lsp::PublishDiagnosticsParams` under a reserved `LanguageServerId` (phpcs `usize::MAX-1`, phpstan `usize::MAX-2`), `DiagnosticSourceKind::Other`, `disk_based_sources` = the tool name, `version: None`. Safe with no registered server (adapter lookup falls back; `ensure!(is_local)` first). An empty list clears that id's entries for the file. **Trap:** `update_diagnostic_entries` is `#[cfg(feature = "test-support")]`; tests and `./script/clippy` (dev-deps enable test-support) pass while the app build fails. Check new non-test code with `cargo check -p zenith` (found 2026-11-18; fixed in `9efcff7fff`).
- PHPCS (WPCS 3.4.1): plain `--standard=PSR12` reports the same columns as `--tab-width=4` (col 7 vs 4 with `0`); `--tab-width=0` also changes which sniffs fire, so map columns back instead. PHP deprecation notices and PHPStan's "Note: Using configuration file" precede the JSON on stdout; PHPStan top-level `errors` can sit beside real `files` findings.

- New since branch (plan 21): `GIT_HARDENING` flags do not cover `filter.<name>.clean` / `process`; `worktree_trusted` in `base_branch` is the only guard, so every git call must start there. PHPStan `ignore.unmatched` messages are dropped (stale baseline entries). Details: `plan/21-project-inspections.md` "As built".

## PHP tooling and Zed extensions

- PHP symbol kinds (checked 2026-11-17 via workspace/symbol): Intelephense 1.18.5 trait = Module(2); PHPantom 0.11.1 trait = Class(5), names namespaced (`App\ZenTrait`); Intelephense + PHPantom: class 5, interface 11, enum 10, function 12. Phpactor 2026.10.07.0: class/interface/trait/enum all Class(5), namespaced, plus PHP stub symbols (zend_*) in results. Phpactor phar at `~/.local/bin/phpactor` (runs on PHP 8.5). Zed's PHP extension installs both under `~/Library/Application Support/Zed/extensions/work/php/`.
- Zed PHP extension: Phpactor is the default LS; Intelephense alternate; licence via `~/intelephense/licence.txt` or `lsp.intelephense.initialization_options.licenceKey`. Xdebug debug adapter built into the PHP extension.
- Zed extensions exist: `laravel-official` (Official Laravel LSP — plan 25 builds on it), `laravel` (community), `http` (.http highlighting only), `twig`, `codebook`, `harper`. No PHPStan/WordPress extension.
- Intelephense `stubs` setting replaces defaults — templates list defaults + `wordpress`.
- phpcbf exit codes: 0 none, 1 fixed, 2 fixed+remaining, 3 error (wrapper treats ≤2 as success).

- PHP servers: since `de9214e025` the fork default is PHPantom (`["phpantom","!intelephense","!phpactor","!phptools","..."]`) with `code_lens` "on" (global only; unverified in the app, plan 41). Before that the defaults turned off `phptools`/`phpantom`/`phpactor`, but a user `languages.PHP.language_servers` ending in `"..."` turns them back on. PHPantom 0.11.1 flags every WordPress function as `Function 'x' not found`; phpactor 2026.10.07.0 dies (`Class "Amp\Failure" not found`). LSP `workspace/configuration` returns `lsp.<server>.settings.<section>`, so Intelephense stubs go under `settings.intelephense.stubs`.

## Look and mockups

- Look sources live outside this repo: `~/GithubProjects/archipelago` (Driftwood theme + Archipelago Icons = Atom Material, MIT) and `~/GithubProjects/zed-config` (owner's default profile). Islands geometry (rounded, gapped docks) can't be a Zed theme — needs `workspace` dock rendering (plan 14 risk). Zed icon themes match exact names/suffixes only (`blade.php`, `test.ts` ok; `*Test.php`, `*Controller.php` impossible).
- Mockup checks: headless Chrome (`--headless=new --screenshot` / `--dump-dom`) has a 500 px minimum window; click-test by injecting a script that clicks, then `--dump-dom` and grep PASS/FAIL. Repo mockups are full HTML docs; artifact copies omit doctype/head (the Artifact tool adds them).
- `ui::Icon::from_path`: a path starting `icons/` is an embedded asset drawn as a single-colour mask; any other path is an external image in full colour. Colour icon themes must load from files on disk (`zenith_look` writes the bundled theme to the data dir). Archipelago Icons is not in Zed's extension registry, so `auto_install_extensions` can't fetch it (2026-11-18).

- Mockup → code: `mockups/claude-design/*.dc.html` hold exact inline CSS. Flatten one to an indented `tag [style]` tree with Python `html.parser` to read sizes/colours (Main board: window 1568×930 r12, title 42 px, rails 40 px / 30 px buttons r7, islands gap 5 r10 border `#1e1f22`, tabs 36, breadcrumbs 28 / 12 px, editor 13.5 px / 24 px lines, status 26 / 12 px). Driftwood already matches most board colours.

## Other

- Plinth (`~/GithubRepos/plinth`, Next.js + Prisma + better-auth multi-tenant CMS) fits the Zenith website (`zenith.plinthsites.com`), not accounts: users are CMS editors, no blob/licence/registry (plan 33).

## Defaults, keys and rails (2026-11-19, home)

- A changed default breaks upstream tests that assumed the old one; pin the old value in each (done: `show_pinned_tabs_in_separate_row` → three `pane` tests call `set_pinned_tabs_separate_row(cx, false)`; `terminal.dock` → right needed no pins in `terminal_view`).
- Key precedence: Zed's `alt-cmd-left/right` and `cmd-shift-f` sit in the `Pane` context; a binding in `Workspace` loses to them. Put Zenith overrides in a `"context": "Pane"` block of `zenith.json` and prove it in `zenith_search` `test_jetbrains_keys_win_in_every_context` (resolve against Zed-only and merged keymaps).
- Rails: `PanelButtons` (vertical) buttons are draggable (`DraggedPanelButton`); `zenith_rails::drop_zone` docks the panel on drop (left top = Left, left foot = Bottom, right rail = Right). Right-click already offers Dock Left/Right/Bottom.
- Tool-window header and ⋮ menu live in `workspace/src/dock.rs` (`zenith_panel_menu`, `zenith_project_panel_menu`); settings writes use `settings::update_settings_file(<dyn fs::Fs>::global(cx), ...)`, current values read from `cx.global::<SettingsStore>().merged_settings()`.
- Row tints in `project_panel` (`zenith_row_tint`): green for test paths, brown for ignored; only when `RailsActive`.
- `zenith_splash`: shown from `zenith::show_splash` right after `release_channel::init`; closes via `observe_new::<Workspace>` after ≥ 1.5 s, hard stop 20 s.
- Bundle times on the home machine with sccache: 15–20 min even after `workspace`/`settings` edits.


## Editor look and features (2026-11-19)

- Code lens exists upstream (`settings_content/src/editor.rs:575-583`, `editor/src/code_lens.rs`, `default.json:467` is `"off"`). The default PHP language server is PHPantom (was Intelephense from `29ab1ddb12` to `de9214e025`; "Phpactor" here was stale), with inlay hints off by default (key names UNVERIFIED). Intelephense inlay hints (1.15.0) and code lens (1.12.0) are Premium only. The zed-config `language_servers` PHP setting is Zed-only, so Zenith runs Phpactor.
- Fold placeholder `⋯` is drawn at `editor.rs:2049` / `fold_map.rs:572` (`display_map.rs:3733` is a test). The fold chevron already shows on folded, cursor and hover rows (`fold.rs:57`). A chip restyle = 1 call site + an appended helper behind `RailsActive`.
- Inlay hint style is tunable only through theme `hint` / `hint.background` (`editor.rs:588-598`). Rounded UI-font chips would need `display_map`/element changes: rejected as high risk (upstream-PR candidate).
- Italic property: Driftwood `property` is already italic (`archipelago.json:1007-1010`). `@property` is also used by css/yaml/json/rust, so "no effect elsewhere" is impossible theme-only. PHP `property_element` capture vs `@variable` precedence is UNVERIFIED.
- The user's Zenith settings live in `~/.config/zenith/settings.json`, separate from the zed-config symlink. Behavior-menu clicks do write there.
- Find in Files popup seeds the query from the selection, or the word at the caret (`zenith_search`).
- The Zenith Dev credentials provider writes plaintext JSON (`zed_credentials_provider.rs:46-60,130-147`). Use `cx.read/write/delete_credentials` for secrets (plans 15, 37).


## Local history and inspections (2026-11-20)

- `FakeFs` panics on non-UTF-8 roots, and APFS refuses non-UTF-8 file names, so a non-UTF-8 path test cannot run on either.
- UNCONFIRMED (security-engineer, 6/10): the single-file / invisible-worktree tool-trust path in `zenith_inspections` may run tools from `<parent>/vendor/bin`.
- UNCONFIRMED (7/10): upstream Zed git hardening does not cover `filter.<d>.clean` / `process`. `zenith_inspections` relies on the trust gate alone (`since_branch.rs` module doc).
- `"tab": null` does not unbind a global `menu::SelectNext`: keymap ranking is by context depth. Bind focus actions (`FocusNextControl` / `FocusPreviousControl`) in the view's own context instead (`zenith.json`, `LocalHistoryList || LocalHistoryView`).
- Under `cfg(test)` the text group interval is 0, so edits do not coalesce into one undo step. Call `set_group_interval` in tests that count undo steps.
- A test binary that loads `zenith.json` with `.expect` needs stub actions for actions defined in other crates, or it panics on the unknown name.
- `cargo sweep --maxsize 40000` reclaims the shared `target/`.

- Upstream-hook exceptions accepted by owner (beyond plan 02's 5 lines): `project_panel.rs` (9 hook lines + 475-line module), `picker` 12 lines, `ui/tab.rs` ~12 lines, External Libraries rework ~10 lines (+1 line for the section menu). Hover card lives in `zenith_card`; Find in Files may clip below ~620px window height.

- PHPantom pinned build (plan 42): `PHPantom-dev/phpantom_lsp` @ `b759b41da61efc31c66e823245cc0118ef5f87bb`, built 2026-11-22 with Rust 1.98.1 (`--locked --ignore-rust-version`, needs 1.99 officially). Installed at `~/.local/share/zenith/tools/phpantom/b759b41da6/phpantom_lsp`, symlink `current`; SHA-256 `1ee2899f7e83caae809d5f5ce1f3c151dbf0c4b88314eaa06c36d3169d1e23ff`. (Machine where it was built; not present on the work machine 2026-11-22. The hash is a record only: Zenith runs whatever `current` points to without checking it.) Security review: PASS for the build with gaps (not read: config-schema.json, composer/bin_plugin.rs, server.rs diff, self_update download check). Do not run `phpantom_lsp update`. `[stubs]` write dropped (cross-project poisoning); only `[indexing] include` is written. Rollback: delete the `current` symlink and `lsp.phpantom.binary`.
