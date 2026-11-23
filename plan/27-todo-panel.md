# 27 — TODO Panel (F9)

> **Status (2026-11-22):** 🟨 panel done in fork `zenith`. `enabled` setting, author/age filters (git blame), commit warning: merged in `zenith` (`9d09c9e6dd`); not seen in an app.

## Goal

JetBrains TODO tool window: find all TODO-style comments, grouped, navigable.

First: check whether upstream Zed or an extension already highlights/lists TODOs.

## Parity checklist

- [x] Patterns (configurable regex, case-insensitive): `TODO`, `FIXME`, `HACK`, `XXX`, `shortcut:` (ponytail debt), `@todo` (must)
- [x] Scopes: project / current file / changed files (git) (must)
- [x] Group by file / by pattern; counts (must)
- [x] Click → jump; live update on save (must)
- [x] Highlight in editor (colour per pattern) (must — via LS hint diagnostics or tree-sitter highlights query)
- [ ] Filter by author (git blame) / age (later)
- [ ] Warn on commit if new TODOs added (later)

## Architecture

- Crate `zenith_todo`; scan only comments: ripgrep-style search (Zed's project search engine — *verify* reusable API) then confirm with tree-sitter that match is inside a comment node.
- Incremental: rescan file on save via `zenith_core::jobs`; full scan on panel open (respect `.gitignore`, `file_scan_exclusions`).
- Highlighting: extension-provided highlights query `(comment) @comment.todo` with injection, or LS emitting `Hint` diagnostics (16).

## Settings

```json
"zenith": { "todo": { "patterns": ["\\bTODO\\b", "\\bFIXME\\b", "\\bHACK\\b", "shortcut:"], "scope": "project" } }
```

## Effort

2–3 days.

## Progress

- 2026-11-19: fork `feat/look` `29216b3d25` + `75d0d2de06` — crate `zenith_todo`: bottom-dock panel, project search + comment check (grammar comment scope, else a `//`/`#`/`/*`/`*` marker before the match), scopes Project / Current File / Changed Files, group by file / pattern, click → line, rescan on save. 3 unit tests (mutation-checked), clippy clean. Not yet seen in a running app.
- 2026-11-19: `3ed32bfd4e` — `zenith.todo.patterns` / `.highlight` (default.json), editor colouring via `HighlightKey::ZenithTodo` (one upstream line), ⌘⇧6 (⌘6 stays Problems, as in PhpStorm). 6 tests.
- 2026-11-19: `294b4c570a` — save rescans only that file; markers inside an open `"`/`'` string skipped; `zenith.todo.scope` + `zenith.todo.dock` (moving the panel saves it).
- Left (marked later): author/age filters, commit warning. Changed Files scope uses git status as of the save (may lag; Refresh). Not yet seen in a running app.
