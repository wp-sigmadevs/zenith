# Fork engineering findings

Facts learned while building Zenith in the fork (`wp-sigmadevs/zed`). Moved verbatim from `CLAUDE.md` §Findings on 2026-11-18; add new findings here under the matching heading, not in `CLAUDE.md`.

## Build, bundle and disk

- Release builds: `script/bundle-mac -i` (dev channel → `Zenith Dev.app`); `-d` debug. Unsigned → ad-hoc codesign, universal links off. `-i` exits 1 *after* "Installed application bundle" (upstream script then mv-s the moved app for the DMG) — app is fine (seen again 2026-11-22: the dmg `mv` fails, app installed). Build regenerates `assets/licenses.md` (stays clean).
- Timings (home, first run): `cargo check -p zed` 11m 13s; bundle zed binaries 11m 10s + remote_server 7m 49s. Plan 17 targets these.
- Disk/time (work machine, 2026-11-16): `target/` reached 73–80 GiB; `cargo clean` freed 80.1 GiB. Full release bundle from clean 115m 11s; full `./script/clippy` after it 8m 45s; incremental bundle after small UI edits ≈ 51m (35m + 16m). Never `cargo clean`/delete `target/` while a build or clippy runs — it killed clippy (`os error 2`).
- Disk (work machine, 2026-11-17): `cargo test -p zed` ≈ +18 GiB; `target/debug/incremental` grows to ≈ 26 GiB (`rm -r` is safe when nothing builds); `./script/clippy` builds the release profile. After big test runs `cargo clean -p <crates>`. Keep ≥ 30 GiB free.
- Disk (home, 2026-11-16): target/ grew 93 → ~120 GiB from one session of per-crate `cargo test` + clippy + one release bundle; disk hit 0 mid-run (ENOSPC breaks Bash/Edit entirely). `cargo clean` freed 135.8 GiB. Check `df -h ~` before test/bundle runs; keep ≥ 30 GiB.
- Per-crate gates are cheap after a warm build: `cargo check` 8 crates ≈ 52 s; `cargo test -p project --test integration <filter>` ≈ 1 min; incremental release bundle 12 min.
- Release bundle can fail on `webrtc-sys` build: it downloads `webrtc-mac-arm64-release.zip` (255 MB) from GitHub releases with no retry; on a flaky line it times out (2026-11-17 home). Fix: `curl -L -C - …` until complete, `unzip -t`, unzip, then `LK_CUSTOM_WEBRTC=<dir>/mac-arm64-release ./script/bundle-mac -i` (`webrtc-sys/build/src/lib.rs` `custom_dir()` skips the download).
- Release bundle 2026-11-18 (work machine, after Rust-file changes in ~10 crates): 39 → 25 GiB free while compiling; `project` alone compiled > 53 min in release; not finished when the session ended (owner shut down).
- `metal` not found (work machine, 2026-11-22): `xcode-select` points at CommandLineTools, so the bundle fails with `unable to find utility "metal"`. Run with `DEVELOPER_DIR=/Applications/Xcode-27.2.0.app/Contents/Developer`. Install the Metal Toolchain with `xcodebuild -downloadComponent MetalToolchain -buildVersion 27B47`; the plain command fails fetching the catalog for 27B52.
- Test runs: `CARGO_INCREMENTAL=0` keeps `target/debug` from growing past the disk budget (2026-11-22).
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
- Zed's buffer loading drops NUL bytes, so a test with NUL bytes in text cannot exercise "binary" paths (2026-11-22, plan 23 binary checkpoints).
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

- Code lens exists upstream (`settings_content/src/editor.rs:575-583`, `editor/src/code_lens.rs`, `default.json:467` was `"off"`; now `:471` `"on"`, see below). The default PHP language server is PHPantom (was Intelephense from `29ab1ddb12` to `de9214e025`; "Phpactor" here was stale), with inlay hints off by default (key names UNVERIFIED). Intelephense inlay hints (1.15.0) and code lens (1.12.0) are Premium only. The zed-config `language_servers` PHP setting is Zed-only, so Zenith runs Phpactor.
- Fold placeholder `⋯` is drawn at `editor.rs:2049` / `fold_map.rs:572` (`display_map.rs:3733` is a test). The fold chevron already shows on folded, cursor and hover rows (`fold.rs:57`). A chip restyle = 1 call site + an appended helper behind `RailsActive`.
- Inlay hint style is tunable only through theme `hint` / `hint.background` (`editor.rs:588-598`). Rounded UI-font chips would need `display_map`/element changes: rejected as high risk (upstream-PR candidate).
- Italic property: Driftwood `property` is already italic (`archipelago.json:1007-1010`). `@property` is also used by css/yaml/json/rust, so "no effect elsewhere" is impossible theme-only. PHP `property_element` capture vs `@variable` precedence is UNVERIFIED.
- The user's Zenith settings live in `~/.config/zenith/settings.json`. Until 2026-11-22 it and `~/.config/zed/settings.json` were symlinks to the same zed-config dotfile (same for `keymap.json`); now Zenith's point at `zed-config/config/zenith-settings.json` / `zenith-keymap.json`. Behavior-menu clicks do write there.
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

- PHPantom pinned build (plan 42, M0 done 2026-11-22, work machine): `PHPantom-dev/phpantom_lsp` @ `b759b41da61efc31c66e823245cc0118ef5f87bb`, built with Rust 1.98.1 (`--locked --ignore-rust-version`; `main` wants 1.99). Installed at `~/.local/share/zenith/tools/phpantom/b759b41da6/phpantom_lsp`, symlink `current`; SHA-256 `2a5765bc0a7da37dfe46a13109611df06c9e2a6585c37001a99e4593073714d4` (checked with `shasum -a 256`). An earlier build of the same commit on the other machine hashed `1ee2899f…e23ff` (builds are not reproducible across machines). The hash is a record only: Zenith runs whatever `current` points to without checking it. Security review 0.11.1..`b759b41`: no new network, process-spawn or file-write sites. Stdio test: `add_action` resolved into WordPress `wp-includes/plugin.php:441`. Do not run `phpantom_lsp update`. `[stubs]` write dropped (cross-project poisoning); only `[indexing] include` is written. On `integrate/batch-b` (`4c4cf69555`) Zenith gives PHPantom its own `XDG_CONFIG_HOME`, so the config no longer touches Zed's. Rollback: delete the `current` symlink and `lsp.phpantom.binary`.

## Settings independence (2026-11-22, `integrate/batch-b`)

- `4c4cf69555`: `.zenith/settings.json` replaces `.zed/` (no longer merged), PHPantom gets a Zenith-only `XDG_CONFIG_HOME`, instance port base 47737 (Zed and Zenith can run side by side).
- `205d3c3827`: Zenith keeps its zed.dev sign-in in its own keychain entry, `credentials_url = https://zed.dev/zenith`.

## Batch B gate and sync (2026-11-22, home)

- zsh does not word-split `$VAR`: build `-p` lists as an array (`P=(${(f)"$(…)"})`, then `"${P[@]}"`), or cargo gets one package named ` zenith -p …`.
- A workspace holds two `ZenithWelcome` views: the tab and upstream's cached empty-pane `WelcomePage` (`workspace/src/pane.rs` `welcome_page`), which stays alive after a tab opens. A page request is now cleared by a deferred reset in `view::request_page`, not by the first view that sees it (`5e13493d92`).
- In a `VisualTestContext`, `cx.update(|window, cx| cx.windows())` leaves out the current window (leased during the update). Read windows through `cx.cx.update(|cx| …)`.
- `Editor::navigate_to_hover_links` jumps instead of opening a multibuffer when all locations fit in one excerpt (rows within 2 × `excerpt_context_lines`). The code-lens "Open in Tab" now calls `open_locations_in_multibuffer` itself (`6e2204e036`).
- `zenith_*` `init`s that read their `enabled` setting need a `SettingsStore` first: tests that call `crate::init` before `EditorLspTestContext::new_*` set `SettingsStore::test(cx)` themselves (`5d12e161da`).
- Upstream "remove dead code" PRs (#67199, #67200) delete accessors only Zenith calls. A sync that fails `cargo check -p zed` on a missing upstream fn: re-add it as a Zenith block at the end of the upstream file.
- `cargo sweep --maxsize 50GB` freed 46 GiB of `target/` (91 → ≈ 45 GiB) without a clean; check `pgrep -x cargo` first (`pgrep -f cargo` matches `.cargo/bin` in other processes' PATH).

## Scratches node, Deployment M1a, PHP config (2026-11-23, home)

- Invisible worktrees are NOT invisible everywhere: `workspace.rs:4170` counts any worktree for "is this window empty", and collab `worktree_store.rs:1293` shares invisible ones too. The scratches store worktree therefore breaks empty-window reuse (code-reviewer, merged over DO NOT MERGE as `5e71fb6096`; fix: hold it only while a visible worktree exists). Search, file finder, trust and git skip invisible worktrees (`project_search.rs:125`, `worktree_store.rs:517`, `trusted_worktrees.rs:440`, `worktree.rs:1375`).
- `add_entry` on a row of an invisible worktree focuses a hidden name editor: upstream inserts the new-entry placeholder row only for visible worktrees (`project_panel.rs` ≈ 4700).
- Root folders are safe from Trash/Delete/Duplicate/Cut: `disjoint_effective_entries_excluding_roots` (`project_panel.rs:4410`) uses `entry_is_worktree_root`, which covers invisible worktrees. F2 on a root is not: guard it in the glue (`394cda4ed0`).
- suppaftp 13.0.0: trusts the PASV reply IP by default (`set_passive_nat_workaround(true)` fixes it), logs `PASS <pw>` at trace (`control.rs:107`; `RUST_LOG`/`ZED_LOG`/user `log` setting can enable it, project settings cannot), does not re-export `futures_rustls` (direct dep needed), and FTPS needs a DNS-name host (raw IP fails closed). Its MLSD parser mistypes `unix.slink=` facts as files.
- System `sftp`: `get` of a remote symlink downloads the target; `!` batch lines run local shell commands; glob escaping does not round-trip, so paths with `* ? [ \` are refused.
- PHPantom has no interpreter key; language level is `[php] version` in `.phpantom.toml`.
- PHPantom config merge (verified 2026-11-23 with `phpantom_lsp analyze`, build `b759b41da6`; its help text agrees): the project `.phpantom.toml` overrides the global config key by key. Tables merge, arrays replace: a project `[indexing] include = [libB]` drops the global include list, and `include = []` empties it; a project file with only `[php] version` or `[indexing] exclude` keeps it. So Zenith's writer touches only `[php] version` and never writes `include` (`php_config.rs` `edit_language_level`); the PHP modal warns when a project file has its own `include`.
- Zenith's PHPantom reads only Zenith's own config dir (Zenith-only `XDG_CONFIG_HOME`), so `~/.config/phpantom_lsp` never applies. Deliberate (settings independence; owner kept it 2026-11-23).
- Adding `suppaftp` re-resolved Windows-only `Cargo.lock` edges (windows-sys → 0.61.2, heck, itertools); cause not established. Fixed on `feat/deploy-m1b` (`d9e9486fab` put upstream's choices back): against upstream `main` the lock now differs only by the new packages (suppaftp, futures-rustls, jiff*, lazy-regex*, zenith crates). Not checked with `cargo metadata --locked`. Re-check after the next upstream sync.

## Review round: scratches, deploy M1b, PHP modal, HTTP history (2026-11-23, work machine)

Opus reviews found and the fixes landed on `zenith` (tests/gate NOT run on the merged tree — owner skipped them to push):

- **Scratches store**: held only while the project has a visible folder, is local and not shared; every store worktree under the store dir is removed on share or dir change (`project_node.rs`). Metadata (id, name, abs_path) can still reach the collab server for a moment (ShareProject is built before `shared()` runs); entries and contents never do. Open scratch tabs lose their worktree on share. A scratch opened from the panel while shared becomes an invisible single-file worktree and is sent to guests like any outside file.
- **Invisible worktrees reach collab guests** (`worktree_store.rs:1293`): also true for the Deployment cached remote copies (`panel.rs`). A real fix needs an upstream hook; owner decided 2026-11-23: document only (works solo), no hook.
- **Deploy**: Keychain account is now `<len>:<user>|<len>:<host>|<port>|<ftp|ftps|sftp>` and the secret is returned only for the exact target; session passwords are bound the same way; Save awaits the Keychain (deletes, then writes) before updating the store. Existing entries (account = username only) no longer match: re-enter once. **Follow-ups done 2026-11-23 (home, `93d6f4d7c5`…`503fca5ea7`, 3 Opus rounds)**: tests for a damaged `servers.json`, server switching, a failing Keychain write, a failing disk write after Keychain writes, session-password order; error text counts real Keychain changes; a note before a saved password is removed; Esc no longer cancels a save (task detached, toast if it fails or clears a password after close); the dialog refuses OK when the saved list changed since it opened; one save at a time including the Keychain phase (an unanswered Keychain prompt blocks saves in every window). Limits: a refused dialog loses its unsaved edits.
- **PHP**: a symlinked `.phpantom.toml` that points outside the project is refused before it is read or written (`resolve_inside_project`; hard links pass, git never makes them). Status-bar PHP probe: 3 s, then one 10 s retry. `write_own_config` takes a lock and a ticket; the newest ATTEMPTED ticket per config path wins.
- **HTTP history masking** (`zenith_http/src/history.rs`): names are matched by segment (see `is_secret_name`); null/bool kept; URL fragments masked; user:pass@ stripped before the query is masked. **Fixed 2026-11-23 (home, `ac604bb44d` `e02f05c5f9`)**: a parsed URL is rebuilt via `Url` with username/password cleared (stored normalised: lowercase scheme, default port dropped); a `{{var}}` template is cut by hand first (any `/`/`\` run after the first colon, authority ends at `/ \ ? #`) so variables keep their spelling. Remaining edge: a scheme colon inside a variable (`{{proto}}//user:pw@host`) still stores the password. Other limits: values under names ending in url/uri/endpoint/length/type/min/max/required stay raw; plural/container names (`secrets`, `tokens`, `access`, `refresh`) and `otp`/`pin`/`cvv`/`ssn` are not masked yet (added 2026-11-23, HANDOFF §3.5; bare `access` stays unmasked). Over-masking accepted: the `Refresh` response header, numeric `tokens` usage counts, `pincode` postal codes (WooCommerce India), map `pin`s, and `*_account_key_id`-style names.
- **Settings**: `toolbar.breadcrumbs` now defaults to false (the path is in the bottom navbar); `zenith.navbar.enabled` (default true, restart to apply) turns the bottom bar off; the project-panel node is called "Scratches" (no console feature exists).
- **Process traps**: `cd X && git ...` makes the git-safety hook fail silently (use `git -C X`); SendMessage resumes an agent on its original model; the disk guard has to be in the same command as the cargo run; hand-backs quoting credential-shaped test values are dropped by the prompt-secret-guard (describe such values in words); `git stash drop` is blocked for the agent (owner runs it with `!`).
- **Process**: `cargo sweep --maxsize 40GB` freed 21–34 GiB each time; three parallel builds on one shared `CARGO_TARGET_DIR` dropped disk under 30 GiB twice. The Supercharger secret scanners flag reports that quote credential-shaped test values: tell reviewers to describe such values in words.
- **cargo audit** (installed 2026-11-23): 22 vulnerabilities, identical to upstream `main`'s lockfile (ammonia, crypto-bigint, h2, libsqlite3-sys, quick-xml x3, quinn-proto, quinn-udp, rsa, url). The suppaftp, futures-rustls, lazy-regex and jiff crates are clean. **2026-11-23 home (`e8ad13ff41`)**: bumped `url` 2.5.9, `quinn-proto` 0.11.19, `quinn-udp` 0.5.16, `ammonia` 4.1.9 → 17 vulnerabilities; the rest are shared with upstream (no compatible fix). Flaky under a full parallel nextest run, pass alone: `zenith_deploy sftp::tests::dropping_the_operation_kills_the_sftp_child`, `zenith_inspections tests::test_a_single_save_looks_up_the_base_beside_the_tools` ("tools never started").

- **Test-only action stubs** (`gpui::actions!(other_crate, [X])` in a test module) panic with "already registered" once the real crate is linked into the same test binary, e.g. through a feature such as `project_panel/scratches` in a workspace-wide nextest run. Use a dev-dependency on the real crate. `zenith_search` tests still stub `zenith_scratches`/`zenith_todo`/`zenith_problems` (latent).

## Session 2026-11-23/24 (home): gate, deploy rounds, plan 44 audit

Upstream facts verified @ fork `503fca5ea7` by two lead-engineer audits (plan 44):
- **Code lens indent bug (upstream):** `editor/src/code_lens.rs:625` uses `indent_size_for_line(row).len`, which counts bytes, so a tab counts as one column; plus `+ 0.5` em at `:733`. On tab-indented PHP the usages line sits ~1.5 em in instead of 4 em. Upstream-PR candidate (plan 44 #4a). Lens colour key `editor_code_lens_foreground` (`:651`) is unset in our themes.
- **Editor right-click hook needs no upstream line:** `Editor::set_custom_context_menu` (`editor.rs:3296`) is checked first (`mouse_context_menu.rs:171`). Upstream's own custom menus (agent message editor, channel notes, commit editor) are all on editors without a project, so a hook limited to full-mode editors with a project overwrites none; re-check with `rg set_custom_context_menu` on every sync.
- **Tab bar end:** `Pane::set_render_tab_bar_buttons` (`pane.rs:859`) is public; the default buttons (`pane.rs:4322`) and `pin_tab_at`/`unpin_tab_at` (`:2715/:2719`) are private.
- **Sticky headers exist upstream**, off by default (`assets/settings/default.json:828-831`, render `editor/src/element/header.rs:42-72`).
- **Italic preview tabs exist upstream** (`editor/src/items.rs:834`); single click opens a preview, `enable_preview_from_file_finder` is false.
- `default.json` code_lens is now `:471` `"on"` (the older note saying `:467 "off"` is stale).
- App menus: `zed/src/zed/app_menus.rs:9-341`, set at `main.rs:861` and `zed.rs:2343`; `MenuItem::checked` exists (`gpui/src/platform/app_menu.rs:174`).

Process:
- Deploy follow-ups needed 3 Opus review rounds; each found an ordering hole in "save while a Keychain prompt is open" that the implementer's tests missed (round 1 detached-save race, round 2 snapshot read at OK time, round 3 PASS). Test both orders of any two-save race.
- Reviewer subagents cannot run cargo (their read-only hook refused `df … && cargo nextest`); the main session runs the checks before merge.
- `target/debug/incremental` reached 57 GiB on the home machine; deleting it while nothing builds is safe and the next warm release bundle took ≈ 17 min.

## Session 2026-11-24 (work): plan 44 steps 1-5a built

Fork `zenith` @ `2af98edadc` (pushed). Gated per chunk; nothing seen in a running app yet.

Build env and disk:
- Every cargo run needs `DEVELOPER_DIR=/Applications/Xcode-27.2.0.app/Contents/Developer` (tests too, not only bundles), else `gpui_apple` fails with `unable to find utility "metal"` (looks like a shader or load failure).
- Agents' test runs regrow `target/debug/incremental` to 36-57 GiB and eat ~19 GiB per run; run with `CARGO_INCREMENTAL=0`. `cargo sweep --maxsize` is age-based and may free almost nothing; `rm -r target/debug/incremental` while nothing builds freed 57 GiB.
- A gate run while an implementer is still editing the same checkout reports half-finished states; run the gate only after the agent reports.

Upstream behaviour found:
- Sticky scroll panic (upstream bug, also on Zed main, hidden because it is off by default): `visible_sticky_header_count_for_point` (`editor/src/scroll/autoscroll.rs`) mixed multibuffer and buffer Points; an expanded deleted diff hunk makes rows differ, so `to_point` panicked in prepaint (agent in-buffer review expands hunks). Fixed by converting through anchors like `refresh_sticky_headers`; carried in the fork (~16 code lines, owner-approved exception), upstream PR candidate. Conflict risk at the next sync.
- `ui_font_size` is also the window rem size: 13 shrank the whole UI to 81% (DynamicSpacing scales by size/16). Kept 16; Inter is applied by family only.
- `agent_ui` re-shows `OpenZedPredictOnboarding` in the palette on every settings change, so hiding branded actions needs a `SettingsStore` observer, and must sit above the `look.enabled` gate (branding hiding is fork-wide).
- `observe_global` activates in a deferred effect; a settings change in the same `cx.update` as `init` is missed (tests use two updates).
- Linux/Windows `ApplicationMenu` (`title_bar/src/application_menu.rs`) drops a submenu nested in a submenu and rebuilds only on `disable_ai` change: keep menu depth to one level; check marks go stale there (deferred).
- `observe_new::<Editor>` runs after the creating update, so our `set_custom_context_menu` overwrites a custom menu set in the same update; no current caller is affected (their editors have no project).
- `ToggleFeature { feature: String }` has a required field, so it never shows in the command palette; keymap form `["zenith_menus::ToggleFeature", {"feature": "navbar"}]`.
- Inter v4.1 bundled from the official rsms/inter release (zip sha256 `9883fdd4a49d4fb66bd8177ba6625ef9a64aa45899767dde3d36aa425756b11e`), static Regular/Italic/Bold/BoldItalic only; SemiBold/Medium resolve to Bold/Regular (~36 call sites use them).

Process:
- Reviewer and planner subagents hit their turn caps (50-60) with no report three times; a message "deliver the report now" via SendMessage recovers it. Give a tool-call budget in the brief. A second SubagentHandback from the same agent is refused: wait for its completion notice before asking again.
- Supercharger blocks edits to files outside the session project root (the fork) until `.supercharger.json` in `~/GithubRepos/zenith` has `additionalRoots` (the file is gitignored).
- Editor right-click menu lost items on first build (Format, Run to Cursor, Evaluate Selection, previews); compare against upstream's default menu (`mouse_context_menu.rs` ~249-313) before replacing any upstream menu.

## Session 2026-11-24 (home): bundle check, tab menu 5b, PHP dialog #7

- **Bundle check (owner, 21:18):** Inter, 40 px title bar, tab padding, Z icons, sticky headers (class + function pinned), Tools menu (9 toggles + IDE Features ›), editor right-click menu, palette (no branding) all seen OK. Preview tab italics works (#12 settled). Usages line ("N references | N implementations") already shows from the LS code lens (#4: author part still unbuilt). Run/Debug is absent from the editor menu on a plain PHP file by design (`editor_menu.rs:164-167`, `:236`: debugger items need a handler).
- **Tab menu (#1) merged `zenith` @ `0c561d328a`, 4 Opus rounds.** Hook: 3 call-site lines in `pane.rs` + ~126-line appended block (`TabMenuTarget`, `set_tab_menu_builder`); menu in `zenith_menus/src/tab_menu.rs`; setting `zenith.tab_menu.enabled` read per click. Findings worth remembering:
  - A menu handler runs inside `pane.update` (`window.handler_for`). Anything that reaches `pane.update` again (git history opener → `workspace.activate_item`) double-updates and panics: wrap in `window.defer`. `Window::dispatch_action` defers itself.
  - Never call `handle_pane_focused` / `set_active_pane` by hand: the tab menu also shows on terminal and debugger panes (workspace subscribes to centre panes only, `workspace.rs:1995`, `:5130`). `pane.activate_item(ix, true, ..)` already makes a centre pane active before a deferred dispatch runs.
  - Resolve the tab by `item_id` at click time, never by the `ix` captured at menu open. `git::*Permalink` actions have no handler outside the project panel: call `workspace::{copy,open}_file_permalink` directly. Reveal through `Project::reveal_path` (WSL path conversion).
  - Tests that call `run(..)` directly with a stub opener missed the panic twice: make stubs do what the real hook does.
- **PHP dialog (#7) merged `zenith` @ `f7e6572648`, 3 Opus rounds, 0 upstream lines.** `PhpModal` reworked in place: level + interpreter rows above one "Include Path" tab, staged edits, Cancel/Apply/OK. Findings:
  - `update_settings_file` only queues the write and logs a parse failure; use `update_settings_file_with_completion` and await it, or Apply reports success while nothing was saved.
  - The base keymap binds `tab → menu::SelectNext` with no context, so `tab_index` alone never works. Pattern: a context block in `assets/keymaps/zenith.json` mapping tab/shift-tab to two actions that call `window.focus_next/prev`, plus `.tab_group()` on the modal root and a `contains_focused` wrap guard (the window tab order is global).
  - Fork-wide gaps: `ListItem` has no `tab_index` (list rows only via arrows); no fork dialog (deploy included) had tab stops before this; Shift-Tab from the first control stays put (gpui cannot find the last stop).
  - Known unfixed: a probe/folder pick finishing during Apply is dropped with a notice that the Apply success clears; level + include change together restart PHPantom twice (`ponytail:` comment).
- **Env:** HOME machine needs no `DEVELOPER_DIR` (Xcode 27.2 is active); the WORK machine does. `cargo fmt --all` by an agent reformatted ~11 files (stashed, not dropped: `git stash drop` is guard-blocked).
- **Process:** a four-round loop per chunk is normal here (reviewers found a real bug in rounds 1-3 each time); the main-session gate never found them, because stubbed tests pass. Give implementers the "never update an entity inside its own update / resolve at click time / stubs must do what the real hook does" lessons up front.

## Session 2026-11-25 (home): tab-bar end #3/#6, Find in Files splitter #18

Merged `zenith` @ `217d6dfa88`, pushed. Not seen in the app.

- **Tab-bar end.** `zenith_rails::tab_bar_end(view, order, visible_fn, cx)` registers a view per toolbar entity id (cleanup via `cx.on_release`); `zenith_rails::init` installs `pane.set_render_tab_bar_buttons` on every centre pane (existing + `PaneAdded`), calls `default_render_tab_bar_buttons` (made `pub`, 1 upstream line) then appends visible views. Last caller of `set_render_tab_bar_buttons` wins; dock panes (terminal, debugger) are not in `workspace.panes()` and keep their own.
- **Hide/show must agree.** The toolbar item is Hidden only when `zenith_rails::draws_tab_bar_end(cx)` (rails && `tab_bar.show` && `show_tab_bar_buttons`). Opus round 1 found ⋮ and markdown buttons vanishing when the tab bar buttons were off; fallback keeps them in the toolbar row (markdown uses `PreviewToolbarSpacer`, observes `SettingsStore`).
- **Empty end slot.** `default_render_tab_bar_buttons` returns `(None, None)` for an unfocused pane; a registered view that renders zero-size still makes `TabBar` draw a bordered end slot. Each view needs a visibility predicate asked at draw time; none visible ⇒ return the stock tuple.
- **Upstream budget.** Plan said 2, real 3 source lines. Tests for upstream-file changes go in a fork file via `#[cfg(test)] #[path = "x_zenith_tests.rs"] mod zenith_tests;` (4 lines) instead of 100 appended lines.
- **Splitter.** Modal is anchored at the top (`modal_layer.rs:303-304`): growing a fixed-list popup moves the handle away from the pointer. Pin the measured body height into `PopupSizes.cards` on mouse-down so the sized path (handle follows pointer) applies. Pinning changes `preview_height`; read it BEFORE pin and write it back after, or short windows (< ~729 px) jump 29-104 px. Stored heights shared across windows must be clamped on read, not only on drag.
- **Test windows hide short-window bugs.** Default test window is 1536x1095; use `simulate_resize` for small-window paths. `cx.notify()` is not covered by gpui tests (harness repaints after every simulated event).
- Reviews: tab-bar end 2 Opus rounds + unreviewed round 3; splitter Opus ×2 NEEDS CHANGES, round 3 unreviewed. Gate-green again missed 4 real bugs.
- Open: Replace-mode row not counted in Find popup min height (36 px + 8 px gap, `find_in_files.rs:~1342`); splitter and ⋮ have no keyboard route; `update_location` notify-only-on-change untested; dock panes untested.

## Session 2026-11-25 (work): inspection widget #11, splitter follow-ups #18

Merged locally on fork `zenith` @ `ecbee8f25d`. NOT pushed (owner pushes). Not seen in the app.

- **Inspection widget (#11)** (`3673357265`, `94eb037dfc`, `35168c7511`, `ecbee8f25d`). `zenith_problems/src/inspection_widget.rs` draws at the tab-bar end through `zenith_rails::tab_bar_end` (priority -1). Per-file errors / warnings / weak counts (weak excludes `is_unnecessary` hints; reuses `zenith_problems::collect`); green check when clean; ↑ ↓ call `Editor::go_to_prev_diagnostic` / `go_to_diagnostic`; counts open the Problems File tab. Shown only when the buffer has a running language server (remote: proven by a `DiagnosticsUpdated` per path). Setting `zenith.inspection_widget.enabled` (unset = on, live; `settings_content/src/zenith.rs`; Tools row in `zenith_menus/src/tools.rs`). 0 upstream source lines (Cargo.lock +3). Dependency `zenith_problems -> zenith_rails` (precedent `zenith_markdown`).
  - Dropped: editor overlay (needs an `editor/src/element.rs` hook), typo counter (no spell checker), toolbar-row fallback. Deferred: browser icons (plan 37 web path, security review then). Upstream bottom `DiagnosticIndicator` kept (right-click Hide).
  - Limits: arrows are `ButtonLike` (an `IconButton` would need `ui` changes for `aria_keyshortcuts`); a clean remote file stays hidden until its first diagnostics update; ~120 px of tab-bar end per pane; arrows also stop on hints the count excludes.
- **Splitter follow-ups (#18)** (`58b9002823`, `35706d614c`). A press without drag pins nothing. Splitter is focusable with aria value/min/max/step, Up/Down nudge, Home/End/Enter, VoiceOver increment/decrement. Key context `FindInFilesSplitter` in `assets/keymaps/zenith.json` (tab → `picker::ConfirmCompletion`, shift-tab → new `zenith_search::FocusPreviousField`). Replace row (44 px) now counted in preview room.
  - Limits: Shift-Tab from the text boxes still runs `Editor::Backtab`; keymap tie-break verified by reading `gpui/src/keymap.rs`, not in the app.
- **Gate pattern.** Sonnet build → main-session gate → Opus + accessibility review → 3 fix rounds. Reviews found a Tab trap (splitter), a stale widget after Save As / rename, and a remote tab-switch bug; tests and the gate missed all three.
- **Tooling.** `assets/keymaps/*.json` are JSONC: plain `json.load` fails on them.
