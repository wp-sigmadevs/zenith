# 32 — Zenith Welcome Screen

> **Status (2026-11-22):** 🟨 merged into fork `zenith` (`2800023217`). Plugin install state, Finish/Skip, New Project and tests: branch `feat/welcome-finish` @ `3da2b49dd3`, not merged.

Earlier status: 🟨 chunks 0–8 built on fork `feat/welcome` (`6f77bb386a`, pushed 2026-11-16): tests green (workspace 307, zed 148, zenith_welcome 12), full `./script/clippy` clean, bundled to `/Applications/Zenith Dev.app`. Pending: owner visual check, README notice removal, merge into `zenith`. Known gaps: Plugins list hard-coded (no installed state); a welcome tab open when the setting is toggled off only switches after reopening.

## Goal

One PhpStorm-style screen that **replaces both** upstream Zed first-run screens:
- Onboarding item — `crates/onboarding/src/onboarding.rs`, `basics_page.rs`
- Welcome page (no project open) — `crates/workspace/src/welcome.rs`

```
┌──────────────┬──────────────────────────┐
│ Zenith       │ [Search projects…]       │
│ Projects   ◀ │ radius-theme   ~/Sites/… │
│ Customize    │   main · 2h ago          │
│ Plugins      │ laravel-crm    ~/Code/…  │
│ Learn        │   dev · yesterday        │
│              │ [New] [Open] [Clone VCS] │
└──────────────┴──────────────────────────┘
```

## Requirements (owner-approved)

1. Left nav: **Projects** (default), **Customize**, **Plugins** (extensions), **Learn** (docs/keymap links).
2. Projects: searchable, keyboard-navigable recent projects (name, path, git branch, last opened); actions New Project / Open / Clone from VCS. WordPress/Laravel/Node templates may be a later phase.
3. Customize absorbs onboarding: theme, base keymap, import VS Code/Cursor settings, vim mode, trust-all. Reuse upstream components/logic, don't copy. "Finish setup / Skip" lives here; returning users never land on setup. Keep upstream's first-run "onboarding seen" flag semantics.
4. Telemetry: **no** "Help improve / fix Zed" toggles on this screen (Zenith ships telemetry and crash upload off). Settings stay.
5. Agent setup: Claude Agent and Codex first. ~~Zed Agent sign-in moves into Customize.~~ Removed 2026-11-16 (owner): no Zed branding or zed.dev sign-in on the welcome screen; keymap shown as "Zenith (default)" (fork `8083776638`, `73c2c17416`). Zenith's own sign-in is plan 33.
6. Recent projects show a framework badge (WordPress / Laravel / Node) from cheap file-presence detection, off the main thread and cached; decide `zenith_core::detect` (plan 15) vs the welcome crate.
7. Logo (`VectorName::ZedLogo` → `assets/images/zed_logo.svg`, now the Zenith glyph): bolder small-size variant — sun r 5.4→8, inner peak opacity 0.45→0.7, main stroke 7.5→9. Asset-only, first chunk.

## Constraints

- New crate (e.g. `zenith_welcome`, GPL-3.0-or-later); upstream gets one-line hooks only (plan 02), ideally one redirect point.
- Never Zed name/logo. Settings key `"zenith"`.
- Fork branch: build on `feat/branding` (`0214f9dbc5`) or `zenith` after it is merged.

## lead-engineer must deliver

1. Verified upstream facts (path:line @ sha): how onboarding and welcome are registered and opened (first launch, no-project startup, actions, Help menu, restore-on-startup), recent-projects source, first-run flag key.
2. Crate plan: name, deps, modules, reused vs new.
3. Upstream hooks: files, one-line change each, count, why unavoidable.
4. Chunks in build order with owner agent, acceptance criteria, `#[gpui::test]` per chunk.
5. Risks: upstream merge churn, behaviour lost from onboarding, keyboard/a11y.

## Implementation plan (lead-engineer, 2026-11-16, verified @ fork `0214f9dbc5`)

Owner decisions: hooks **approved** (7 feature lines + ~10 one-time umbrella/settings lines) · keep `restore_on_startup = LastSession` · agents card in **Customize** (Claude, Codex first; Copilot CLI, Cursor under "More agents") · bolder logo in **all** `VectorName::ZedLogo` uses (asset-only).

**Crates:** `crates/zenith` (umbrella, feature `welcome` default-on, `zenith::init`, re-exports `show_onboarding_view`) and `crates/zenith_welcome` (GPL-3.0-or-later, `[lib] path = "src/zenith_welcome.rs"`; modules `view`, `projects`, `customize`, `agents`, `plugins`, `learn`, `detect`). `detect` moves to `zenith_core` on second use (plans 19/20/24/25).

**Upstream hooks:**
- H1–H4 `workspace/src/welcome.rs`: `WelcomeOverride` global (fn → `Option<AnyView>`), `custom` field on `WelcomePage`, set in `new` (~:283), early-return in `render` (~:418). Covers launchpad, ShowWelcome, Finish, deserialize.
- H5 `zed/src/main.rs:37`, H6 `zed/src/zed/open_listener.rs:20`: import `show_onboarding_view` from `zenith`.
- One-time: root `Cargo.toml` members + workspace deps; `crates/zed/Cargo.toml` dep; `zenith::init(cx)` **after** `onboarding::init` (`main.rs:784`) so our action listeners win; `settings_content`: `mod zenith`, `zenith: Option<ZenithSettingsContent>` field (check whether `flattened_deserialize!` at ~:406 needs it).
- `OpenOnboarding`: no hook — global listener; `stop_propagation` when enabled, `propagate` when off.

**Setting:** `"zenith": {"welcome": {"enabled": true}}` in new `settings_content/src/zenith.rs`; off ⇒ override returns `None`, upstream screens render.

**Mapping:** 1 left nav (Projects default) · 2 Projects = embedded `Picker` over `WorkspaceDb::recent_project_workspaces`, fuzzy search, keyboard, New/Open/Clone · 3 Customize = own render fns calling upstream logic (theme, base keymap, import VS Code/Cursor, vim, trust, Zed Agent sign-in); no theme preview tiles (upstream private) · 4 no telemetry section/events · 5 agents via `AgentRegistryStore` + `agent_servers` install (as `basics_page.rs:539-597`) · 6 `detect.rs`: background `Fs` scan, cached — `artisan`→Laravel; `wp-config.php`/`wp-includes`/`wp-content`/theme `style.css` header/plugin header→WordPress; `package.json`→Node; branch from `.git/HEAD` (incl. `gitdir:`) · 7 `assets/images/zed_logo.svg` bolder (sun r 5.4→8, inner peak opacity .45→.7, stroke 7.5→9).

| # | Chunk | Owner | Gate | Effort |
|---|---|---|---|---|
| 0 | Logo asset | gpui-ui-engineer | bundle visual check | 0.25d |
| 1 | Umbrella, crate skeleton, settings, `zenith::init` | rust-core-engineer | `cargo check -p zenith -p zed` | 0.5d |
| 2 | H1–H6, nav shell, first run, OpenOnboarding | gpui-ui-engineer | `cargo test -p workspace -p zenith_welcome` | 1d |
| 3 | Projects picker | gpui-ui-engineer | `cargo test -p zenith_welcome` | 1.5d |
| 4 | `detect.rs` | rust-core-engineer | same | 0.75d |
| 5 | Customize | gpui-ui-engineer | same | 1.5d |
| 6 | Agents card | agentic-integrations-engineer | same | 0.5d |
| 7 | Plugins (zed-kit extension ids) + Learn | gpui-ui-engineer | same | 0.5d |
| 8 | Tests + `./script/clippy` | test-engineer | `cargo test -p onboarding -p workspace -p zed` green | 1d |

Total ≈ 7.5 days. Review: code-reviewer, accessibility-engineer (nav/picker/focus), performance-engineer (no startup main-thread I/O).

**Tests:** detect fixtures on `FakeFs` (Laravel, WP core/theme/plugin, Node, Laravel+Node→Laravel, empty, `.git/HEAD` ref/detached/gitdir, cache hit); gpui: override on/off, OpenOnboarding → Customize, first run writes `first_open`, picker filter + Enter opens, agents order + install, no telemetry ids.

**Open:** `flattened_deserialize!` requirement; startup cost of `WelcomePage::new` DB query while overridden; `git::Clone` without a workspace; Learn links point to upstream docs (named as upstream).
