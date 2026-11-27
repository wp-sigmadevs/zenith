# 44 — PhpStorm parity, owner review round 1

Status: ⬜ plan approved (owner 2026-11-24): D1–D15 as recommended except D3 (minimap stays **on**). Source: owner review of `Zenith.app` built from fork `zenith` @ `503fca5ea7`; screenshots and the 18 requests in [`mockups/owner-review-2026-11-23/`](../mockups/owner-review-2026-11-23/README.md). Two lead-engineer audits @ `503fca5ea7` (read-only). Anything unchecked is *verify*. More rounds will follow (owner: "there are a lot more").

## Summary

| # | Request | Where it lives today | Fix | Effort | Upstream lines |
|---|---|---|---|---|---|
| 1 | Tab right-click menu = PhpStorm | `workspace/src/pane.rs:3123-3484` | `zenith_menus::tab_menu` via one call site + appended block | 1 d | 1 + block |
| 2 | Editor right-click menu = PhpStorm | `editor/src/mouse_context_menu.rs:246-333` | `Editor::set_custom_context_menu` from `observe_new::<Editor>` (full mode + project only) | 1–2 d | 0 |
| 3 | Orphaned ⋮ row | QuickActionBar in toolbar `zed/src/zed/quick_action_bar.rs:101-126` | hide toolbar item; render ⋮ + extras at the tab bar's right end via `pane.set_render_tab_bar_buttons` | 1 d | 2 |
| 4 | Usages line like PhpStorm | upstream code lens `editor/src/code_lens.rs:634-740` | 4a tab-aware indent (upstream bug: tabs counted as 1 column, `:625`); 4b style hook → UI font, muted colour, "usages", author | 1–1.5 d | 3 |
| 5 | Sticky class/function headers | upstream `sticky_scroll`, off (`default.json:828-831`) | turn on; pin old value in affected upstream tests | 0.5 d | 1 |
| 6 | Code / split / preview buttons relocated | `zenith_markdown/src/zenith_markdown.rs:42-60` (toolbar row) | render through item 3's tab-bar extras, left of ⋮ | 0.5 d | 0 |
| 7 | PHP dialog = PhpStorm | `zenith_php_tools/src/php_modal.rs` | level + interpreter above tabs, include list with + / − / folder, vendor rows green, staged Cancel / Apply / OK | 1.5–2 d | 0 |
| 8 | Double "Scratches" | `project_panel/src/zenith_libraries/scratches_node.rs:12-13`, root path from `project_panel.rs:8548` | "Scratches and Consoles" › "Scratches", drop path suffix | 1 h | 0 |
| 9 | Remote Host panel + Deployment dialog = PhpStorm | `zenith_deploy/src/panel.rs:583-705`, `dialog.rs:668-1030` | field-by-field relayout, real tabs, Mappings + Excluded Paths, browse / Autodetect root, LIST-compat | ≈ 4 d | 0 |
| 10 | Two AI icons | Agent Panel and Agent Review both `IconName::ZenithBot` | Agent Review → `file_diff.svg` | XS | 0 |
| 11 | Inspection widget + browser icons at editor top-right | bottom `diagnostics/src/items.rs` | widget in `zenith_problems` (`inspection_widget.rs`) at the tab-bar end via `zenith_rails::tab_bar_end`; browser icons deferred (need a URL source) | 2 d + | 0 (Cargo.lock +3) |
| 12 | Preview tab italic | upstream already italic (`editor/src/items.rs:834`); single-click opens preview | check in app; optionally preview from ⇧⇧ / file finder | XS | 0–1 |
| 13 | Bigger navbar font | `zenith_navbar.rs:469-502` `LabelSize::Small` | Default size (or follow UI font) | 1 h | 0 |
| 14 | Tools menu controlling every feature; PhpStorm menu bar | `zed/src/zed/app_menus.rs:9-341` | `zenith_menus` reorders upstream items into File / Edit / View / Navigate / Code / Refactor / Run / Tools / Git / Window / Help; Tools lists every Zenith feature with ☑ enable toggles | 2–3 d | 2 (−4 reverted) |
| 15 | Taller title bar | `ui/src/utils/constants.rs:18` 34 px | 40 px, traffic lights y 9 → 12 | S | 2 |
| 16 | More left spacing in tabs | fork block in `ui/src/components/tab.rs` (8 px) | 12 px | XS | 1 (in forked block) |
| 17 | No visible Zed | menus, icons, font, palette, minimap | audit list below | S each | 0 |
| 18 | Draggable splitter in Find in Files | fixed `PREVIEW_HEIGHT` (`zenith_search/src/style.rs:22`, `find_in_files.rs:1434`) | row-resize handle, session-stored height, clamped | 0.5 d | 0 |

New crate: `zenith_menus` (GPL-3.0-or-later, Cargo feature `menus`): `app_menu.rs`, `tools.rs`, `editor_menu.rs`, `tab_menu.rs`. Touched: `zenith_rails` (`tab_bar_end.rs`), `zenith_problems` (`inspection_widget.rs`), `zenith_look`, `zenith_navbar`, `zenith_markdown`, `zenith_search`, `zenith_php_tools`, `zenith_deploy`, `zenith_agent_review`, project_panel's `zenith_libraries`.

## Item details

### 1 Tab menu

Close / Close Other / Close All / Close Unmodified / Close All but Pinned / Close Tabs to the Left / Right: actions exist (`CloseActiveItem`, `CloseOtherItems`, `CloseAllItems{close_pinned}`, `CloseCleanItems`, `CloseItemsToTheLeft/Right`). Copy Path/Reference ›: absolute / relative exist; file name, repo-root path new; PHP FQN new (from LS document symbols). Split Right / Down and Split and Move: exist (`SplitRight/Down{mode}`, *verify* variant). Pin Tab: `TogglePinTab` (pin/unpin helpers private → public wrappers in appended block). Configure Editor Tabs…: `OpenSettingsAt`. Reopen Closed Tab: `ReopenClosedItem`. Override File Type: `language_selector::Toggle` (*verify*). Run › / Debug ›: partly (task spawn, debugger start, scratch run, HTTP run). Open In ›: Finder / Terminal / GitHub exist; Browser missing. Local History ›: show history exists. Git ›: file history exists, others *verify*. Rename File…: new. Bookmarks ›: plan 28 (hidden until built). Deployment ›: plan 37 M2 (shown disabled). Open Tab in New Window: new.

### 2 Editor menu

Show Context Actions (`ToggleCodeActions`), AI Actions › (add to thread, inline assist), Paste, Copy / Paste Special › (cut / copy / copy and trim / permalink; paste from history new), String Manipulation › (case/sort actions, *verify* names), Go To › (definition / declaration / type / implementation / usages / calls, `zenith_search` GoToClass / GoToSymbol, go to line), Folding › (*verify*), Rename…, Refactor › (`zenith_refactor`: RefactorThis, ExtractMethod, ExtractVariable, ChangeSignature, MoveClass, SafeDelete), Generate… (plan 09), Run / Debug ›, Open In ›, Local History ›, Git ›, Compare with Clipboard (*verify*), Deployment › (plan 37). The custom closure must keep upstream's "move cursor to click" step. Risk: overwriting a future upstream full-mode custom menu → `rg set_custom_context_menu` on every sync.

### 4 Usages line

- 4a: `group_lenses_by_row` counts indent in bytes (`code_lens.rs:625`, `IndentSize.len`), so on tab-indented PHP the lens sits ~1.5 em in instead of 4 em; also drop the `+ 0.5` (`:733`). Built (fork branch `feat/plan44-screenshots`, not merged): 5 changed lines in the function body + a 13-line helper + a test; PR candidate for upstream, carried until merged.
- 4b: appended `set_code_lens_style` hook (same pattern as `set_code_lens_locations_handler` `:2199`) + one call site in `build_code_lens_renderer` + re-export `editor.rs:82`. `zenith_look` returns UI font at 0.9 × UI size, "N usages", two-space separator, people icon + blame author of the declaration row (`GitBlame::blame_for_rows`, capture the `Entity<GitBlame>` at block build; *verify* the editor isn't leased during block render).
  - Built (same branch): 3 hook sites + 1 import line + a 62-line appended block + 1 re-export line in the fork. Lens title "N reference(s)" → "N usage(s)" and the blame author live in `zenith_look/src/code_lens.rs`.
- Theme: set `editor.code_lens.foreground` to PhpStorm's code-vision grey.

### 7 PHP dialog

| PhpStorm | Change |
|---|---|
| "PHP language level:" dropdown above tabs with feature description, ? help | move above tabs; static version→feature table in `php_config.rs`; tooltip ? |
| "CLI Interpreter:" dropdown + "…" | move above tabs; "…" = file picker to add a php binary |
| Tabs Include Path / PHP Runtime / Analysis / Composer Files | Include Path only; others hidden until owner screenshots |
| Toolbar + / − / folder; one scrollable list; vendor rows green | single `uniform_list`, vendor rows `Color::Success`, read-only |
| Footer ? / Cancel / Apply / OK | stage edits, one write per Apply / OK (one PHPantom restart); removes `clicks` / `restart_pending` bookkeeping |

Include paths stay global (plan 39 decision) unless the owner says per project.

### 9 Remote Host + Deployment

Panel: bordered full-width host field with type icon; "…"; Collapse All; refresh (green); disconnect = red ✕ (JetBrains' ✕ is Close, not Disconnect; Zenith shows Disconnect as ✕); Locate opened file (built in plan 37 C7, merged locally; "Edit Local File" is not built); remove the duplicate gear; tree root "Name (host)" with errors as a child row ("No authentication data provided") instead of the red banner.

Dialog (top to bottom): real tab strip Connection / Mappings / Excluded Paths; "Visible only for this project" at top; Type dropdown with icon (FTPS default + insecure-FTP callout kept); Host + Port one row; Username + "Login as anonymous"; Password + "Save password" + ? (tooltip: Keychain); Test Connection under password; Root path + remote folder browse + ? + Autodetect (`PWD` after login, *verify* transport); "Web server URL" + open button; inline "⚠ Username is not specified"; Advanced: Passive mode, Show and process hidden files, Use LIST command › Compatible with old version of listing children (`list_compat`, built: FTP changes into the folder with `CWD`, then sends a bare `MLSD` / `LIST` / `LIST -a` with no path argument; field in `AdvancedOptions`, `config.rs`; applies only with LIST once the next chunk lands; the JetBrains meaning is UNVERIFIED) / Instead of MLSD; Number of connections, keep-alive each N s, keep-alive command (fields exist in `config.rs:53-55` but unused → show with plan 37 M3). Mappings: Local / Deployment / Web path table (add `web` field). Excluded Paths: local and deployment lists (`excluded_local` / `excluded_remote` exist, unused). Security review mandatory (browse / Autodetect connect with stored credentials).

### 11 Inspection widget

Merged locally on fork `zenith` @ `ecbee8f25d` (commits `3673357265`, `94eb037dfc`, `35168c7511`, `ecbee8f25d`; unpushed; 4 review rounds, Opus + accessibility). Not seen in the app. Implemented in `zenith_problems/src/inspection_widget.rs`, drawn at the tab-bar end via `zenith_rails::tab_bar_end` (priority -1). Per-file errors / warnings / weak warnings (weak excludes `is_unnecessary` hints; reuses `zenith_problems::collect`); green check when clean; ↑ ↓ call `Editor::go_to_prev_diagnostic` / `go_to_diagnostic`; clicking the counts opens the Problems File tab. Shown only when the buffer has a running language server (remote projects: once a `DiagnosticsUpdated` arrived for the path). Setting `zenith.inspection_widget.enabled` (unset = on, applies live; `settings_content/src/zenith.rs`; Tools menu row in `zenith_menus/src/tools.rs`). 0 upstream source lines (Cargo.lock +3). New dependency `zenith_problems -> zenith_rails` (precedent `zenith_markdown`).

Deviations from the first plan: editor top-right overlay dropped (needs an `editor/src/element.rs` hook); typo counter dropped (no spell checker); browser icons deferred to the plan 37 web path (http/https only; security review then); no toolbar-row fallback; upstream bottom `DiagnosticIndicator` kept (right-click Hide).

Known limits: arrows are `ButtonLike`, not `IconButton` (no `aria_keyshortcuts` without touching `ui`); a clean remote file stays hidden until its first diagnostics update; the widget takes ~120 px of tab-bar end per pane; arrows also stop on hints the count excludes.

### 14 Menu bar and Tools

`main.rs:861` and `zed.rs:2343` call `zenith::app_menus(upstream_builder, cx)`; `zenith_menus` matches upstream items by action and places them in PhpStorm's bar; unplaced items go to the nearest menu; a test asserts no upstream action is lost. Rebuild on Zenith setting changes. Revert the 4 renamed lines in `app_menus.rs` (net upstream diff shrinks).

Tools: AI Assistant › · New from Template / New PHP Class · Create Command Line Launcher · Local History › · Scratches › · TODO › · Inspections › · Inspection Widget · HTTP Client › · Deployment › · Start SSH Session · PHP › · WordPress › · Laravel › · Next.js › · Markdown › · Run Command · IDE Features › (Search Everywhere, Navigation Bar, Tool Window Rails, Zenith Look, Islands, Title Bar Additions, Hover Card, External Libraries, Welcome). Each feature gets ☑ Enabled (`zenith.<f>.enabled`); navbar, templates, rails, islands, look, search, inspections need a restart (notification offers it); the rest apply live (*verify* each crate observes its flag).

### 17 Visible Zed-isms

a. Menus "Selection", "Go", Help items to zed.dev (release notes, email, docs, repo, Twitter, join the team), "Check for Updates" while updates are off, Collab Panel → fixed by item 14.
b. Zed-logo icons (`zed_agent*.svg`, `zed_assistant.svg`, `zed_predict*.svg`, `ai_zed.svg`) in quick action bar, agent panel, edit prediction button, onboarding, sidebar → swap SVG contents for Lucide glyphs (assets only).
c. UI font → Inter 13 (owner 2026-11-24, D2).
d. Edit-prediction status button with no provider → hide.
e. Palette "get merch" / "open docs" → hide via command-palette filter.
f. Minimap: stays on (owner 2026-11-24).
   R1 built (branch `feat/plan44-screenshots`, not merged, not pushed): `rebrand_text` in `crates/zenith/src/brand.rs`; hooks in `zed.rs` for default settings, default keymap, semantic token rules and vim bindings; initial user settings/keymap comments say Zenith; `test = false` removed from `crates/zenith/Cargo.toml` so its tests run. Owner answers: keep Zed service names; show base keymap as "Zenith (default)" (display only); leave "Zed (Default)" theme names. Also on the branch: G1 pinned tabs share one row (`show_pinned_tabs_in_separate_row` false in `default.json`); G2 end-of-line blame left alone (no `element.rs` hook).
g. Later rounds: Git panel layout (plans 10/14), settings / keymap UI (29), Ctrl-Tab switcher.

## Upstream budget

| Feature | Lines |
|---|---|
| menus (`zenith_menus`): Cargo ×2, main.rs:861, zed.rs:2343, pane.rs:3125 (+ appended block), −4 reverted | 5 |
| tab bar end (built): pane.rs:4325 `pub`, zed.rs:1494, quick_action_bar.rs:93 + 4-line `#[path]` test hook | 3 (+4 test hook) |
| look: constants.rs:18, zed.rs:393, tab.rs forked block | 3 |
| editor: default.json sticky_scroll, code_lens.rs 4a + 4b call site, editor.rs:82 re-export | 4 (5 with preview-from-finder) |

`code_lens.rs` and `pane.rs` are hot upstream files: one call site each, appended blocks, PR candidates (code-lens tab indent; tab context-menu extension point).

## Build order (quick wins first)

| Step | Items | Owner | Check |
|---|---|---|---|
| 1 | 10, 13, 8, 16 + 15 (one `ui` rebuild) | gpui-ui-engineer | crate tests, `cargo check -p zenith` |
| 2 | 17b icon SVG swap, 17d/e | gpui-ui-engineer | `cargo test -p icons` |
| 3 | 5 sticky headers, 12 check | rust-core-engineer | `cargo nextest run -p editor` |
| 4 | 14 menus + Tools | rust-core-engineer + gpui-ui-engineer | `cargo test -p zenith_menus` |
| 5 | 2 editor menu, 1 tab menu | gpui-ui-engineer | `-p zenith_menus -p workspace` |
| 6 | 3 + 6 tab-bar end | gpui-ui-engineer | `-p zenith_rails -p zenith_markdown -p zed` |
| 7 | 18 splitter | gpui-ui-engineer | `-p zenith_search` |
| 8 | 4 usages line | rust-core-engineer + gpui-ui-engineer | `-p editor -E 'test(code_lens)'`, `-p zenith_look` |
| 9 | 7 PHP dialog | gpui-ui-engineer | `-p zenith_php_tools` |
| 10 | 9 Remote Host + Deployment | gpui-ui-engineer + rust-core-engineer | `-p zenith_deploy`, security review |
| 11 | 11 inspection widget (browser icons deferred to plan 37) | gpui-ui-engineer | `-p zenith_problems -p zenith_menus` |

Every chunk: Sonnet builds, Opus reviews (code-reviewer + accessibility; performance for 2 / 4 / 11; security for 9, and for 11 only with browser icons), new tests proven to fail without the fix, `df` ≥ 30 GiB, then a bundle check in the running app before ✅.

## Owner decisions

| # | Question | Recommendation |
|---|---|---|
| D1 | Title bar 40 px (PhpStorm) or 42 px (design board)? | 40 |
| D2 | UI font: Inter 13 (bundled, OFL), system font, or keep Plex 16? | Inter 13 |
| D3 | Minimap off by default? | **owner: keep on** |
| D4 | Sticky headers on for everyone? | on |
| D5 | Usages line: author shown, end-of-line blame hidden on that line, "usages" wording? | yes ×3 |
| D6 | Code-lens indent fix as an upstream PR, carried until merged? | yes |
| D7 | Scratches: "Scratches and Consoles" › "Scratches" (reverses earlier "leave")? | yes |
| D8 | PHP dialog in-window, staged Cancel / Apply / OK, "…" = file picker? Send screenshots of PHP Runtime / Analysis / Composer Files | yes |
| D9 | Deployment: hide unwired connection / keep-alive fields until M3; keep Name row; remove gear | yes |
| D10 | Preview tabs also from ⇧⇧ / file finder? | yes |
| D11 | Navbar font follows UI font size? | yes |
| D12 | Open-in-browser URL source (deployment web path vs built-in server) and browsers | deployment web path; system default browser first |
| D13 | Drop plugin entries (GitToolBox, Highlight, Diagrams, Gist) and new items (Open in New Window, Column Selection, Generate, Paste from History) for round 1? | drop |
| D14 | Treat menus / tab bar end / look / editor as separate 5-line upstream budgets? | yes |
| D15 | Agent Review icon | `file_diff` |

## Open *verify*

Diagnostic summary API; `language_selector::Toggle`; case / fold / git action names; Restart action; spacing token for 12 px; command-palette filter API; clipboard-diff action; overlay positioning; SplitMode "move" variant; editor lease during block render; `zenith_is_scratch` in `scratches_off.rs`; PHP outline query for sticky headers; `LabelSize::Ui`; FTP `PWD`; live observation of each `enabled` flag; whether `zenith_postfix` has an `enabled` setting.

### Settled 2026-11-24 (read-only audit of fork `feat/plan44-quick-wins`, paths in `~/GithubRepos/zed`)

- **Step 1 built** (fork `zenith` @ `f835bb7f97`): 12 px tab padding uses `DynamicSpacing::Base12` (token exists; `LabelSize::Ui` not needed, navbar uses `LabelSize::Default`). Row 8 upstream budget is 1 (4 lines inside the fork's appended `impl ProjectPanel` block, `project_panel.rs:8549`), not 0.
- **17b icons**: the Z logo is drawn by `ai_zed`, `zed_agent`, `zed_predict` and `zed_predict_{up,down,error,disabled}`; `zed_assistant` and `zed_agent_two` are sparkles (leave). Swap SVG contents only; icon names and icons tests stay.
- **17c font**: Inter is not bundled (`assets/fonts` has ibm-plex-sans, jetbrains-mono, lilex). Add `assets/fonts/inter/*.ttf` + OFL; `default.json:75` `".ZedSans"` → `"Inter"`, `:87` `16` → `13`.
- **17d**: `default.json:2001` `"provider": "zed"` → `"none"` hides the button; run `edit_prediction_ui` tests.
- **17e**: hide with `CommandPaletteFilter::hide_action_types` (`command_palette_hooks.rs:45`): `GetMerch`, `OpenDocs`, `OpenStatusPage`, `feedback::OpenZedRepo`, `EmailZed`.
- **Item 5**: PHP outline comes from the installed `php` extension's `outline.scm` (class/function/method/interface/enum/trait); which editor tests assume sticky off is unknown until `cargo nextest run -p editor` after the flip.
- **Item 14**: `reload_menus` runs only on `disable_ai` change (`zed.rs:2168`), so the Tools ☑ toggles need their own reload trigger; gpui `MenuItem::Action` supports `checked` / `disabled`. Restart = `workspace::Reload`; Compare with Clipboard = `DiffClipboardWithSelection`.
- **Items 1/2**: `workspace` cannot depend on `zenith_menus` (cycle) → register a global tab-menu builder, one call site at `pane.rs:3129`. `pin_tab_at` / `unpin_tab_at` / `is_tab_pinned` / `entry_abs_path` are private. Editor menu: `set_custom_context_menu` (`editor.rs:3296`) skips upstream's full-mode check and cursor move, so the closure redoes both; copy `zenith_look/src/bulb.rs:64-71`. `SplitMode::MovePane` exists (`pane.rs:216`). `language_selector::Toggle` exists.
- Still unverified: diagnostic summary API, overlay positioning, editor lease during block render, FTP `PWD`, live `enabled` observation, `zenith_postfix` `enabled` setting.

## Doc fixes when building

plan 14 (zenith_menus, tab-bar end, 40 px, 12 px tabs), plan 02 (app-menu swap call sites), plan 34 (markdown switcher, inspection widget placement), plan 37 checklist (Locate, LIST-compat, Autodetect, browse root, web path, error rows), plan 39 (PHP modal built; item 7 spec; Scratches label reversed), plan 41 (4a / 4b), fork-findings (`set_custom_context_menu` as the editor-menu hook; `default.json` code_lens line now `:471` "on").

## Round 2: owner app check of the C1-C7 bundle (2026-11-27 night, home)

Owner ran `/Applications/Zenith.app` (`dc688c8b70`) on `easy-demo-importer` and sent 8 screenshots. Nothing below is investigated or built. Owner: "others will follow when I have the time". Rule: every item ends with an app check, and the target look is PhpStorm exactly.

| # | Report (owner's words, condensed) | Seen in the screenshot | State |
|---|---|---|---|
| R1 | "No file opened: it's just blank, need something" | Empty editor area beside the Project tree, no hints | ⬜ build an empty state like PhpStorm's (Search Everywhere, Go to File, Recent Files, Open Project hints with their keys) |
| R2 | "Improve the UI, I need exactly like PhpStorm" | Project tree: whole rows tinted for ignored/changed paths, header buttons `+ ⤢ ⤡ ⋮ −`, title bar shows two branches (`main` / `master`) | ⬜ compare with a PhpStorm window (capture read-only, see memory `screenshot-running-app`); decide the tree tint, the double branch (which is which, UNKNOWN) |
| R3 | "Not exactly like PhpStorm" (Deployment dialog, Recent Files, Search Everywhere, Terminal) | Deployment dialog: plain-text tabs, Type as text choices (FTPS FTP SFTP), red "Insecure: plain FTP" banner always shown for FTP, Test Connection bottom left. Recent Files: left list shows raw action names truncated ("Scr zenith_scratches::T…", "Rer zenith_deploy::Tog…") and "WordPress Hook" cut by its key. Search Everywhere: Hooks tab greyed, footer "Open In Right Split". Terminal: tab "easy-demo-importer — zsh", toolbar `+ ✦ ⊞ ⤢` | ⬜ BUG: tool-window rows without a name show the action id; ⬜ each dialog to be matched against PhpStorm's (Settings > Deployment, Recent Files, Search Everywhere, Terminal) |
| R4 | "Where is the omz style theme?" (terminal) | Plain zsh prompt `srafiz@SMs-Mac-mini easy-demo-importer %`, "Last login… You have new mail." | ⬜ UNKNOWN cause: login shell runs but no oh-my-zsh theme visible (is `~/.zshrc` read? is the font missing prompt glyphs?). Check `$SHELL`, `ZSH`, the terminal's env and font before guessing |
| R5 | "Scratch files do not save automatically like PhpStorm, need Cmd-S; I want auto save" | n/a | ⬜ scratches (plan 04): save on edit/idle/focus loss, no prompt |
| R6 | "An added external library has no Remove in the right-click" | n/a | ⬜ plan 39: add "Remove" (and check Rename/Reveal) to the External Libraries node's context menu |
| R7 | "Removing an added directory in Configure Include Path does not remove it" | PHP dialog: Include Path list in green with a monitor icon per row; the `−` button is greyed; `Apply` greyed | ⬜ BUG (plans 35/39): select a row, `−` stays disabled or the removal is not saved; reproduce first |
| R8 | "I AirDropped the app to a colleague; PHPCS does not work in his app" | n/a | ⬜ UNKNOWN: likely per-user tool paths (settings hold `/Users/srafiz/.local/share/zenith/tools/...`), tools not bundled, or Gatekeeper quarantine on the AirDrop copy. Check where `phpcs` is looked up and what the bundle ships |
| R9 | (seen only) Open Project dialog: "Open "wordpress" (~/WPProjects/wordpress) in: This Window / New Window / Attach / Cancel" with "Don't ask again" | dialog matches PhpStorm's wording | ✅ looks right, check Attach works |
| R10 | (seen only) PHP dialog shows `Apply` and `OK` both; language level "Auto (composer.json)", CLI "Auto (first PHP found)" | | ✅ present |

Later items from the owner: add here as they arrive.
