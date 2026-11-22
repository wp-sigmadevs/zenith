# Plan 39 — External Libraries

**Goal:** Add a read-only "External Libraries" node at the bottom of Zenith's project panel that aggregates dependency folders (`vendor/`, `node_modules/`, WordPress core path) — matching PhpStorm's behaviour.

**Crate:** `zenith_external_libraries` (GPL-3.0-or-later)
**Upstream hooks:** ≤ 5 one-line hooks in `project_panel.rs` (keep separate from plan 05 C3's hook).

> Status legend: ⬜ not started · 🟨 in progress · ✅ done
>
> **Status (2026-11-21):** merged into fork `zenith` @ `7ef1dc7da2` (from `feat/external-libraries` @ `3ec7baecab`). Reviewed (code + security, 2 rounds); fixes landed: library folders hidden only under detected roots, `zenith.external_libraries.enabled` honoured, separate library context menu (`crates/project_panel/src/zenith_libraries.rs`). Wired into the app via `project_panel` hooks. NOT built: M3 (read-only banner, trust exclusions) and hook 5 (no drag-and-drop). Known gaps: see Progress.

## Problem

Zed's `hide_gitignore` setting hides `vendor/` and `node_modules/` entirely, making dependencies invisible. With `hide_gitignore: false`, they appear inline — huge, noisy, and mixed with source files. Neither is ideal for PHP/JS development.

PhpStorm solves this with an "External Libraries" node at the bottom of the project tree: a collapsed, read-only, visually distinct section that shows dependency folders without cluttering the source tree.

## What counts as a library

A directory is an "external library" when ALL of these hold:
1. It matches a known dependency pattern (see table below), AND
2. A corresponding lock/manifest file exists in the worktree root (proving it's a managed dependency, not a random `vendor/` dir)

| Pattern | Manifest/lock file | Notes |
|---|---|---|
| `vendor/` | `composer.json` OR `composer.lock` | PHP (Composer) |
| `node_modules/` | `package.json` OR `package-lock.json` OR `yarn.lock` OR `pnpm-lock.yaml` | JS/TS (npm/yarn/pnpm) |
| `wp-includes/`, `wp-admin/` | `wp-load.php` OR `wp-config.php` (at worktree root) | WordPress core (project opened at WP root) |

Nested `node_modules/` (e.g. `vendor/somepackage/node_modules/`) are NOT listed separately — they appear as children of the top-level library folder when expanded.

### Future extensibility

The detection table is a `Vec<LibraryPattern>` in settings, so users can add custom patterns. Default:

```jsonc
// zenith.external_libraries
{
  "enabled": true,
  "patterns": [
    // built-in defaults; user can extend
  ]
}
```

## Architecture

### M1 — Detection and data model (~2 days)

New crate `zenith_external_libraries` with:

```rust
/// A detected external library root.
pub struct ExternalLibrary {
    /// Worktree that contains this library.
    pub worktree_id: WorktreeId,
    /// Path relative to worktree root (e.g. "vendor", "node_modules").
    pub path: Arc<RelPath>,
    /// Human-readable label (e.g. "Composer (vendor)", "npm (node_modules)").
    pub label: SharedString,
    /// Icon name for the library type.
    pub icon: IconName,
    /// Entry ID of the directory in the worktree.
    pub entry_id: ProjectEntryId,
}

/// Detects external libraries in a worktree snapshot.
pub fn detect_libraries(snapshot: &WorktreeSnapshot) -> Vec<ExternalLibrary> { ... }
```

Detection is cheap: check the worktree root's children for known directory names, then verify the manifest file exists. No deep scanning.

**Tests:**
- FakeFs with `vendor/` + `composer.json` → detected
- FakeFs with `vendor/` but no `composer.json` → not detected
- FakeFs with `node_modules/` + `package.json` → detected
- WordPress root with `wp-includes/` + `wp-load.php` → detected
- Nested `node_modules/` inside `vendor/` → not listed at top level

### M2 — Project panel integration (~3 days)

**Upstream hooks (project_panel.rs):**

1. **Filter hook** (~line 4776 in `update_visible_entries`): When `RailsActive` and external libraries enabled, skip entries whose path matches a detected library root. This removes them from the normal tree.

2. **Append hook** (after the worktree loop in `update_visible_entries`): After all worktree entries are collected, append an "External Libraries" synthetic section with the detected libraries as children.

3. **Render hook** (in `render_entry`): When rendering an entry that belongs to the external libraries section, use a distinct style (muted colour, library icon, "(read-only)" suffix or lock icon).

**UI behaviour:**
- "External Libraries" is a collapsible node at the very bottom of the project panel, below all worktree roots
- Collapsed by default
- When expanded, shows one child per detected library (e.g. "vendor (Composer)", "node_modules (npm)")
- Each library child is itself expandable, showing the actual directory contents (lazy-loaded from the worktree snapshot — Zed already has the entries if `is_ignored` dirs are expanded)
- Files inside are **read-only** in the editor (soft lock: show a warning banner, not a hard block)
- Library entries have a dimmed/muted text colour (use `text.muted` from theme)
- No drag-and-drop onto or from External Libraries entries
- Right-click menu: "Reveal in Finder", "Copy Path", "Copy Relative Path" only (no New File, Rename, Delete, etc.)

**How the entries flow:**

```
update_visible_entries()
  for each worktree:
    iterate entries via GitTraversal
    HOOK: if entry.path matches a detected library root → skip (don't add to visible_worktree_entries)
  HOOK: if any libraries detected → append ExternalLibrariesSection to visible_entries
    each library root → its children from the worktree snapshot (lazy, on expand)
```

The external libraries section uses a synthetic `WorktreeId` marker (or a separate `Vec<ExternalLibraryEntry>` stored alongside `visible_entries`) so the render path can distinguish it.

**Tests:**
- Project panel with `vendor/` + `composer.json`: vendor not in main tree, appears under External Libraries
- Expand External Libraries → shows "vendor (Composer)"
- Expand vendor → shows packages
- With `hide_gitignore: true`: vendor still hidden from main tree, still visible in External Libraries
- With `hide_gitignore: false`: vendor appears in External Libraries (not duplicated in main tree)
- No External Libraries node when no libraries detected
- Sabotage: remove the filter hook → vendor appears in both places (test FAILs)

### M3 — Read-only enforcement and trust (~1 day)

**Read-only:**
- Files opened from External Libraries entries show a notification bar: "This file is from an external library and should not be edited directly."
- The file is still editable (not hard-locked) — same as PhpStorm. The warning is informational.
- Implementation: set a buffer flag when opening from an External Libraries path, render a banner in the editor chrome.

**Trust / security:**
- External library directories are **not** scanned for tasks, debug configs, or agent tools (`.zenith/`, `.zed/` inside `vendor/` or `node_modules/` are ignored)
- The `is_local_settings_component` check in `tool_permissions.rs` already covers `.zed/`; ensure `.zenith/` inside library paths is also excluded
- Library paths are excluded from `file_scan_exclusions` override — even if a user adds `!vendor/` to always-include, the External Libraries section still shows them there (don't fight the feature)

**Tests:**
- `.zenith/settings.json` inside `vendor/` is not loaded as project settings
- `.zed/tasks.json` inside `node_modules/` is not loaded
- File opened from External Libraries path shows the warning banner

### M4 — Indexing cost management (~1 day)

**Problem:** `vendor/` and `node_modules/` can contain 50K+ files. Scanning them is expensive.

**Solution:** Zed already handles this — `is_ignored: true` directories are only scanned when expanded. The External Libraries node's children are loaded from the worktree snapshot, which only populates ignored directories when the user expands them. No change needed to the scanning behaviour.

**What to verify:**
- Expanding "External Libraries" does NOT trigger a full scan of `vendor/` — only the top-level children
- Expanding a package inside `vendor/` triggers scanning of that one package directory
- Memory/time: opening a large project (e.g. Laravel app with 2000+ Composer packages) with External Libraries collapsed has no measurable overhead vs. without the feature
- `file_scan_exclusions` patterns that exclude `vendor/**` still work — External Libraries shows the directory but its contents may be empty (matches Zed's existing behaviour)

### M5 — Settings and polish (~1 day)

**Settings (`zenith` key in settings.json):**

```jsonc
{
  "zenith": {
    "external_libraries": {
      // Show the External Libraries node in the project panel.
      // Default: true (when RailsActive)
      "enabled": true
    }
  }
}
```

**Polish:**
- Icon: use a library/book icon (`IconName::Library` — add `library.svg` to assets if needed)
- Keyboard navigation: External Libraries node is reachable via arrow keys after the last worktree entry
- Search: files inside External Libraries are excluded from "Find in Files" by default (Zed already excludes `is_ignored` entries from search). "Include ignored" toggle includes them.

## Upstream hook budget

| Hook | File | Purpose | Lines |
|---|---|---|---|
| 1 | `project_panel.rs` `update_visible_entries` | Skip library roots from normal tree | 1 |
| 2 | `project_panel.rs` `update_visible_entries` | Append External Libraries section | 1 |
| 3 | `project_panel.rs` `render_entry` | Dispatch to external library rendering | 1 |
| 4 | `project_panel.rs` context menu | Restrict menu for library entries | 1 |
| 5 | `project_panel.rs` drag-and-drop | Disable DnD for library entries | 1 |
| **Total (plan)** | | | **5** |

**Actual (2026-11-21):** `project_panel.rs` carries 9 hook lines plus a 475-line fork module (`zenith_libraries.rs`) inside the upstream crate, over the budget of 5. Owner decision needed (plan 02). Hook 5 (drag-and-drop) is not built.

Each hook is a one-line call to a function in `zenith_external_libraries`.

## Build order

```
M1 (detection)  →  M2 (panel integration)  →  M3 (read-only + trust)
                                               M4 (verify indexing cost)
                                               M5 (settings + polish)
```

M3, M4, M5 can be done in parallel after M2.

## Effort

~1.5 weeks (1 dev + Claude). M1–M2 are the bulk; M3–M5 are small.

## Risks

1. **Worktree scanning cost**: Mitigated by Zed's lazy scanning of ignored dirs. Verify with M4.
2. **Upstream merge conflicts in `project_panel.rs`**: Plan 05 C3 adds 1 hook line. Keep hooks separate (different line ranges). The file is 8600+ lines — conflicts unlikely if hooks are appended.
3. **Synthetic entries in the visible_entries model**: The project panel assumes all entries come from real worktrees. The External Libraries section needs a clean abstraction boundary (separate struct, not hacked into `VisibleEntriesForWorktree`).

## Out of scope

- Downloading/updating dependencies (plan 24 Package Manager Panel)
- Indexing library source for go-to-definition (handled by language servers: Intelephense, Phpactor)
- Showing library versions inline (future: read `composer.lock` / `package-lock.json`)
- Multiple worktree support for the same library type (e.g. monorepo with multiple `package.json`) — handle in a follow-up

## Progress

(Updated 2026-11-21, after review; statuses below are post-review.)

| Milestone | Commit | Status |
|---|---|---|
| M1 detection | `ef1ff99115`, merged `7ef1dc7da2` | ✅ done, reviewed |
| M2 panel integration | `ef1ff99115`, merged `7ef1dc7da2` | 🟨 built + reviewed; hook 5 (no drag-and-drop) built (`7ac3658fe4`, `f6ec1f24f7`); hooks over budget |
| M3 read-only + trust | `banner.rs`; `zenith_local_settings_trust` gate (`project_settings.rs:1262`) | 🟨 built, in `zenith` @ `d58e761135`; not checked in a running app — audit 2026-11-22 |
| M4 indexing verification | not verified | ⬜ no measurement recorded |
| M5 settings + polish | `7ef1dc7da2` | 🟨 `zenith.external_libraries.enabled` done; other polish not verified |

Known gaps (review 2026-11-21): 9 hook lines + 475-line module in `project_panel` vs budget 5; `zenith_row_kind` per-frame cost; `zenith_menu` hook untested; no running-app check.
