# 34 — Claude Design: implementing the target look

> **Status (2026-11-22):** 🟨 `feat/look` merged into fork `zenith`. Owner: fork-only parts; upstream-heavy items listed, not built. Editor look = PhpStorm (replaces the earlier indent-background choice): thin indent guides by default (`6e11ff3720`), parameter hints only for literal arguments, as pills (`ed5d116df1`), amber 16 px gutter bulb (`80c305331b`); Find in Files colours every row and the preview is editable (`0a317ac1f1`); all on `integrate/batch-b` @ `205d3c3827` (not built into an app).

Originally: ⬜ plan (2026-11-17) — run `lead-engineer` on each step before code.

## Goal

Make the running editor match `mockups/claude-design/` (11 boards, Driftwood dark). One board at a time, cheapest wins first, language server or extension before fork code, fork code in `zenith_*` crates behind one-line upstream hooks (plan 02).

## Decided

- Default look: theme Driftwood + icon theme Archipelago Icons (plan 14, mockups session 2026-11-17).
- Colour roles: blue = the IDE, orange `#ff7a3d` = anything an agent did. Warnings must not look orange — warning colour gets its own hue (amber/yellow) via theme override.
- One scene per screen: agents stay in the title-bar chip until they need you (boards 1, 4).
- `zenith-v1.html` is a feature inventory only; `zenith-v2.html` and `claude-design/` are the target.

## Boards → owner

| Board | What it needs | Built from | Fork cost | Plan |
|---|---|---|---|---|
| 11 Components | Tokens: buttons, pills, status dots, tab states (incl. "pending agent changes", review tab) | Theme overrides first; `ui` component variants only where a theme token is missing | Low | 14 |
| 1 Editing — title bar | Project badge, branch, Search Everywhere box (⇧⇧), run config + run/debug, agent chip "1 running · review 2" | New `zenith_title_bar` crate, one hook in upstream `title_bar`; run config from Zed tasks | Low | 14 |
| 1 Editing — editor | Inline WP warning under the line, parameter-name hints, hook icons in the gutter | WP rules = diagnostics from `wp-hooks-ls`, shown by Zed inline diagnostics; hints from Intelephense inlay hints; gutter icons need a fork hook (*verify*: no extension API for custom gutter icons) | None / Medium | 19 |
| 7 Hook hover | Listener list across plugin + active theme | `wp-hooks-ls` hover — no fork | None | 19 |
| 5 Search Everywhere | One modal: classes, files, symbols, WP hooks, actions | `zenith_search` modal reusing file finder, project symbols, command palette pickers; hooks source from `wp-hooks-ls` workspace symbols | Medium | 14 |
| 4 Agent popover | Chip opens a short task list | Part of `zenith_title_bar`; data from plan 22 task model | Low (after 22) | 22 |
| 3 Agent review | One review tab per task, accept/reject per hunk, run tests in worktree, accept/reject all | Zed's agent diff multibuffer (*verify* it can target a worktree branch) + plan 22 worktrees | Medium | 22, 23 |
| 6 Inline agent edit | Pending agent hunk inline, accept/reject in place | Zed's inline agent diff already does this for its own agent (*verify*); extend to external agents (Claude Code, Codex) via plan 06 | Medium | 06, 23 |
| 2 Debugging | Xdebug paused, inline values, frames/variables bottom | Zed debugger + PHP extension Xdebug adapter; mainly default dock layout | Low | 03 |
| 8 Run | PHPUnit in Docker, green gutter run icons per test | Runnables via tree-sitter `runnables.scm` (exists for PHP *verify*); results panel = plan 07; Docker = plan 11 | Medium | 07, 11 |
| 9 Tool windows | Left/right **stripes** with panel icons, overflow for Tests/Scratches/Bookmarks/Composer/DB | Zed has dock buttons in the status bar only — stripes need upstream workspace changes | High | 14 |
| 10 Narrow | <900 px panels overlay the editor; <500 px title bar icons only | Upstream workspace/dock layout | High | 14 |
| — Islands | Rounded, separated panels | Upstream workspace/pane styling; merge cost on every upstream sync | High | last, owner decides |

## Order

1. **Look** (board 11): bundle Driftwood + Archipelago Icons as defaults, theme overrides for warning hue and agent accent. Settings/assets only.
2. **Title bar** (board 1, top): `zenith_title_bar` with badge, branch, Search box (opens existing finder until step 4), run config, agent chip (static until plan 22).
3. **Editor** (boards 1, 7): `wp-hooks-ls` diagnostics + hover; turn on inline diagnostics and inlay hints by default; then decide the gutter-icon fork hook.
4. **Search Everywhere** (board 5). New `zenith_search` crate: one modal, tab strip (All · Classes · Files · Symbols · Hooks · Actions), one `Picker` whose delegate fans out to sources; results carry a kind label. Upstream change: the ⇧⇧ binding, the title bar box action, and a 28-line block appended to `command_palette.rs` (shared action history).
   - 4a: modal + tab strip + **Actions** source (available actions, fuzzy match, as the command palette). ⇧⇧ stays on the file finder.
   - 4b: **Files** source (project path fuzzy match, as the file finder). Then move ⇧⇧ and the title bar box to Search Everywhere.
   - 4c: **Symbols** (LSP workspace symbols) and **Classes** (the same, filtered to class/interface/trait/enum kinds).
   - 4d: **All** tab: sources merged with kind labels; tab switching from the keyboard.
   - 4e: **Hooks**, once `wp-hooks-ls` (plan 19) exists.
5. **Agents** (boards 3, 4, 6): after plans 22/23.
6. **Debug and Run** (boards 2, 8): layout defaults, then plan 07.
7. **Stripes, Narrow, Islands** (boards 9, 10): only after measuring the upstream diff each needs; owner decides.

## Progress (fork `feat/look`: merged into `zenith`; the PhpStorm-look fixes are on `integrate/batch-b`, not in an installed app)

| Step | State | Commits |
|---|---|---|
| 1 Look | ✅ Driftwood default dark, amber warnings. Icons: the registry install never worked (not published); since `19998b882b` Archipelago Icons ship in the app (`zenith_look`, written to the data dir so they keep colour). Same commit makes the owner's `zed-config` profile the defaults (JetBrains keymap + Mono 17/1.8 bundled, brackets, guides, hint backgrounds, TS tokens, terminal bottom) | `9f80280cd7` `9d34458b99` `9162b7bf21` |
| 2 Title bar | ✅ initials badge, Search box (opens file finder), ⇧⇧ in `assets/keymaps/zenith.json`, run config ▾ + ▶ + 🐞, agent chip. All in one title bar section (`zenith_title_bar::middle`) | `919e5f8be6` `100b4a55d1` `b2d94bee7e` `a8dd38e358` `315b12f9b1` |
| 3a Editor defaults | ✅ inlay hints on; inline diagnostics on in `3500e8d135`, then off by default in `29ab1ddb12` (squiggle + hover; noisy language servers) | `3500e8d135` `29ab1ddb12` |
| 3b/3c | ⬜ 3b waits for `wp-hooks-ls` (plan 19); 3c gutter hook = owner decision | — |
| 4a Search Everywhere | ✅ `zenith_search` crate: modal, tab strip (only Actions live), ⌘⇧A / Ctrl+Shift+A (PhpStorm Find Action), background fuzzy match, history shared with the command palette | `1cd9d84071` `898e214e14` `fae7a95a0c` |
| 4b Files | ✅ Files tab: fuzzy project paths as the file finder, file icons, recent files on an empty query, `file:row:col` and `file:start-end` jumps, ⌘-Enter splits; honours `file_finder.file_icons` and `include_ignored`. ⇧⇧ and the title bar box open Search Everywhere (Files until 4d's All); ⌘⇧A = `zenith_search::FindAction`; the other shortcut switches tabs, the same one closes | `9bdf1df19b` `3f279d9829` |
| 4c Symbols, Classes | ✅ Symbols: LSP workspace symbols as project symbols (server filter, fuzzy rank, in-project first, `path:line` shown); Classes: same, kinds class/interface/enum/struct, plus Module in `.php` (Intelephense 1.18.5 reports traits as Module, PHPantom 0.11.1 as Class; checked live). Queries debounced 100 ms. Enter jumps, ⌘-Enter opens in the adjacent pane | `8c584c576e` `1ce4504494` |
| 4d All | ✅ All tab: classes, files, other symbols, actions (8 each, kind label per row); files/actions show before the language server answers. ⇧⇧ opens All; Tab / Shift-Tab cycle ready tabs (`SearchEverywhere > Editor` in `zenith.json`, beats the picker's Tab by load order) | `65c87e35ba` |
| 4e Go to… keys | ✅ ⌘O Go to Class, ⌘⇧O Go to File, ⌘⌥O Go to Symbol, ⌘E Recent Files → Search Everywhere tabs; ⌘⇧E Recent Locations → its own list (file:line from the panes' navigation history, newest first, fuzzy; the project panel keeps ⌘1). Bound in `zenith.json`, repeated under the editor contexts that bind the same keys deeper. A keymap test resolves them in editor, terminal and project panel against the real keymap files. Linux/Windows: Ctrl+O / Ctrl+E stay with the terminal and vim mode | `6e60df402e` `e650075134` `1abb437945` `f28e2895ca` |
| 4f Modal look | ✅ Search Everywhere as the board: accent tab, 🔍 + `esc` field, kind badges (C/I/E/T/m/f/p), bold name + greyed folder/`file:line`/shortcut, kind label once per group (`6fcdddc86e`). ⌘E Recent Files popup: title, "Show edited only", tool windows column, recent files (`380148492e`). Recent Locations: code line per place (`5e88ca6de4`). Every picker gets the 🔍 + `esc` field under Zenith chrome (`4057c62286`). ⌃Tab Switcher (`342cbec861`), All-tab filter funnel (`7d745cebf5`), closed-file snippets (`963ac3283e`), Go to Line:Column dialog (`ee17d4e47e`). Not seen in a running app |
| 4e Hooks | ⬜ waits for `wp-hooks-ls` (plan 19) | — |
| 6a Layout | ✅ project/outline/git panels left, agent right | `20fff816a2` |
| 9a Rails | ✅ 36 px icon rails both sides (new `zenith_rails` crate, feature `rails`): left = left-dock panels on top, bottom-dock panels (terminal, debug) at the foot, as the board; right = right-dock panels. Reuses `PanelButtons` (vertical option); the status bar's dock buttons go blank while rails are on. Upstream: ~50 lines in `dock.rs` + `workspace.rs` (rails slot, side padding, rails painted after the zoom overlay). Not seen in the app yet. **Missing icons:** DB, web and Local History have no panel in Zed | `f283f3b60f` + zoom fix | Problems button (project diagnostics) on the left rail: `12339f1e9b`.
| 11b Defaults | ✅ From the Main board: tab file icons + git colours, minimap always, line-ending and encoding buttons in the status bar, terminal docked right (button on the right rail; ⌃` toggles it, ⌃⇧` new terminal — already bound upstream). Tests of settings, editor, search, diagnostics, outline, vim, terminal_view pass. Not seen in the app yet. **Status bar still missing:** agent message (plan 22), `PHP 8.5 · docker` (plan 35) | `f2f3431ec6` `dbb21a4ba1` |
| 10a Islands | ✅ Panels as rounded, separated islands: darker window background, 2 px gap, rounded border on each dock and the editor area (`IslandsActive` global set by `zenith_rails`). Upstream: ~43 lines in `workspace.rs` + 3 in `dock.rs`, all guarded by the global (no effect when off). Not seen in the app yet; corner radius, gap and border colour are guesses against the board | `feat(zenith_rails): rounded, separated panel islands` |

## Main board check (2026-11-18, code vs `Main.dc.html`; not yet seen in a running app)

| Board element | State |
|---|---|
| Driftwood, Archipelago Icons, JetBrains Mono 17 / 1.8 | ✅ built in (`19998b882b`) |
| Title bar: mark, badge, project, branch, Search Everywhere, run config ▶ 🐞, agent chip, settings | ✅ (`4e9c0c5916` adds mark + settings) |
| Agent chip counts "1 running · review 2" | ⬜ plan 22 |
| Left rail top: Project, Commit, Local History | Project, Git ✅; Local History ⬜ plan 05; Outline (Structure) also shown |
| Left rail foot: TODO, Hooks, Terminal, Problems | Terminal, Debug, Problems ✅; TODO ⬜ plan 27; Hooks ⬜ plan 19 |
| Right rail: Agents, Database, HTTP | Agents ✅; Database ⬜ plan 12; HTTP ⬜ plan 08 |
| Tool window header "Project ··· ×" | ✅ Project + Structure (`4e9c0c5916`); "···" menu not added |
| Project root shows its path (`~/Sites/…`) | ✅ `d30c0ad763` (with islands on) |
| Tabs with file icons + git colours, breadcrumbs | ✅ (11b) |
| Active tab accent line | ✅ `d30c0ad763` (with islands on; theme `text_accent`) |
| Gutter hook icons, inline WP warning | ⬜ plan 19 (inline diagnostics ✅) |
| Inlay parameter hints with background | ✅ |
| Status bar: problems count, PHP version, language server, position, UTF-8, LF, indent | ✅ (indent `4e9c0c5916`; PHP via `zenith_php_tools`) |
| Status bar agent message "Claude Code waiting for review" | ⬜ plan 22 |
| Collab button (not on board) | hidden by default |

## Per-board method

1. Read the board (`mockups/claude-design/<Board>.dc.html`).
2. List what Zed already does; note the gap.
3. Place each piece: language server → `zenith_*` crate → one-line upstream hook.
4. Build, test, clippy.
5. Compare: headless-Chrome screenshot of the board vs a screenshot of the running app.

## Open

- Gutter hook icons: extension API or fork hook? Check Zed source before step 3.
- Agent review on a worktree branch: does Zed's agent diff support it, or does plan 23 need its own view?
- "Accept all": **decided neutral** (2026-11-18). Zenith's Keep All / Reject All buttons in `agent_ui` already use the default style; keep it that way when the review board is built.
- Stripes/Islands: worth the merge cost? Measure the upstream diff first.
