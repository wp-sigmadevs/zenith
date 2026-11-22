# 14 — UI: PhpStorm-style Toolbar & Interface

> **Status (2026-11-22):** 🟨 fork-only parts (owner 2026-11-22; upstream-heavy items listed, not built). On `integrate/batch-b` @ `205d3c3827` (tests + `cargo check -p zenith` + clippy pass; not built into an app): bottom navigation bar `zenith_navbar` (`a5d7ef188c`), 8 px before the tab icon (`d064cf5ba7`). Run widget (configurations, stop, rerun): branch `feat/run-widget` @ `35648a90f2`, not merged.

## Goal

PhpStorm "New UI" look and flow: main toolbar with project/branch widgets and a run widget, tool-window stripes (icon bars) on the left/right, navigation bar, configurable toolbar buttons.

## Parity checklist

| PhpStorm element | Zenith implementation | Priority |
|---|---|---|
| Main toolbar: project widget (switch/recent projects) | Extend title bar | must |
| VCS widget: branch, update, commit, push, history | Title bar (reuse `git_ui` actions) | must |
| Run widget: config selector + ▶ Run, 🐞 Debug, ■ Stop, ↻ Rerun | New: lists tasks + debug scenarios (+ test runs from 07) | must |
| Search Everywhere, Settings buttons | Title bar buttons → existing actions | must |
| Tool-window stripes (left/right vertical icon bars) | New stripe component around docks | must |
| Drag icons between stripes, hide/show | Persisted layout | later |
| Navigation bar (path breadcrumbs above editor) | Zed has breadcrumbs — restyle/position | nice |
| Editor tab look (pinned, close-on-hover, coloured by dir) | Zed tab bar settings + theme | nice |
| Status bar widgets (line:col, encoding, LF, indent, LS status, interpreter) | Zed status bar + new items (interpreter from 11, DB/HTTP env) | must |
| Customizable toolbar (add/remove buttons) | `zenith.toolbar` setting | must |
| Compact mode | Spacing setting | later |

## UX layout

```
┌ Title/Main toolbar ─────────────────────────────────────────────────────┐
│ [≡] Project ▾  ⎇ main ▾  ✓ ↑ ⟲      ...      [Config ▾] ▶ 🐞 ■ ↻  🔍 ⚙ │
├──┬───────────────────────────────────────────────────────────────┬──┤
│📁│ breadcrumbs: src › Http › Controllers › UserController.php    │🗄│
│🔀│ tabs                                                           │🌐│
│🧪│ editor                                                         │🤖│
│🕘│                                                                │  │
├──┴───────────────────────────────────────────────────────────────┴──┤
│ status: ⚠ 2  ✗ 0 │ PHP 8.3 (app) │ dev env │ 42:7 │ UTF-8 │ LF │ 4sp │
└────────────────────────────────────────────────────────────────────────┘
```
Left stripe: Project, Git, Tests, Local History, Scratches. Right stripe: Database, HTTP, Agent. Bottom: Terminal, Problems, Run, Debug.

## Architecture

- **Title bar**: Zed's `title_bar` crate renders the top bar (*verify*). To minimize merge conflicts, create `zenith_title_bar` (copy + extend) and swap it in at the single place the title bar is constructed — one-line upstream hook. Re-sync from upstream `title_bar` monthly.
- **Run widget**: model = union of `.zed/tasks.json`, `.zed/debug.json` scenarios, recent test runs; selected config persisted per workspace (`db`). Buttons dispatch existing task/debugger actions.
- **Tool-window stripes**: Zed currently shows dock toggle icons in the status bar (*verify*). Add `zenith_stripes`: vertical icon bars rendered beside left/right docks — requires a hook in `workspace` dock rendering (highest merge-risk point; keep it to one call site). Stripe items read from the registered `Panel`s (icon, tooltip, toggle action) so new panels appear automatically.
- **Status bar**: add `StatusItemView`s (interpreter, HTTP env, DB connection) — no upstream change needed.
- **Configurability**:
  ```json
  "zenith": {
    "toolbar": {
      "left": ["project", "vcs_branch", "vcs_actions"],
      "right": ["run_widget", "search", "settings"]
    },
    "stripes": {
      "left": ["project_panel", "git_panel", "zenith_tests", "zenith_local_history", "zenith_scratches"],
      "right": ["zenith_db", "zenith_http", "agent_panel"],
      "hide_status_bar_dock_buttons": true
    }
  }
  ```
- **Icons**: use Zed's existing icon set (Lucide-based) + new SVGs in our own `assets/icons/zenith/`. **Don't copy JetBrains icons** until their licence is confirmed (IntelliJ Community is Apache-2.0, but verify icon assets and "New UI" icons specifically; keep attribution if used).
- **Theme**: ship a "Zenith Light/Dark" theme approximating Islands/New UI colours (theme JSON, no code).
- **Default look (decided 2026-11-17)**: bundle the owner's Archipelago extensions (`wp-sigmadevs/archipelago`) and default to theme **Driftwood** + icon theme **Archipelago Icons** (Atom Material Icons, MIT, © Elior Boukhobza — ship `LICENSE-ICONS` with the bundle). Settings-only, no code. Check brand-logo icons (WordPress, Laravel, Docker…) against their usage rules before a public release. Rejected: a generated in-house icon pack (108 types vs ~11k names covered, hand upkeep). Target look: `mockups/zenith-v2.html`.

## Milestones

1. Status bar items (no upstream touch) — warm-up.
2. Run widget in title bar (fork `title_bar` → `zenith_title_bar`).
3. Project + VCS widgets.
4. Tool-window stripes + hide status-bar dock buttons.
5. Toolbar/stripe configuration + persistence.
6. Theme + breadcrumbs/tab polish.

## Tests

- Run-widget model merge (tasks + debug + tests) unit tests.
- gpui render smoke tests for title bar and stripes.
- Manual: all panels togglable from stripes; keyboard shortcuts unchanged.

## Risks

- `workspace` and `title_bar` are hot upstream code → frequent conflicts. Mitigation: copy-and-swap for title bar, single hook for stripes, monthly re-sync.
- Accessibility: every toolbar/stripe button needs a tooltip + action name (keyboard and command-palette reachable).
- Islands geometry (target look in `mockups/zenith-v2.html`): colours and icons come from theme/icon-theme JSON (Driftwood + Archipelago Icons, no code), but rounded, gapped panels (editor, docks and bottom panel as separate islands) cannot be expressed in a Zed theme. It needs dock/pane rendering changes in `workspace` (*verify* where docks and the center pane are drawn) — the same hot code as the stripes hook. Mitigation: do it in the stripes hook's call site, behind a `zenith.ui.islands` setting, and drop it if it breaks the merge-cost kill criterion.

## Effort

2–3 weeks. Can start right after 04 (it gives 04–08 their entry points).
