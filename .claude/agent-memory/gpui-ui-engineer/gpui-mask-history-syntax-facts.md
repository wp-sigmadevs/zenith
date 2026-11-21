---
name: gpui-mask-history-syntax-facts
description: Verified kvp/PopoverMenu-test/syntax-highlight facts from zenith_search Find in Files M1b (fork cd18204d79 on feat/search-parity)
metadata:
  type: project
---

- KV store: `db::kvp::KeyValueStore::global(cx).read_kvp(key)` (sync) / `db::write_and_log(cx, move || async move { store.write_kvp(k, v).await })` (`crates/db/src/kvp.rs`, `db.rs:287`); first user in fork was `zenith_welcome.rs:111`. Needs `db.workspace = true` (adds 1 Cargo.lock line, unavoidable). Tests fall back to a process-shared TEST_APP_DATABASE (workspace test-support), so unit-test pure structs and seed via the API in gpui tests.
- Syntax colours of a line: `snapshot.chunks(Point(row,0)..Point(row,len), LanguageAwareStyling{tree_sitter:true, diagnostics:false})`, `chunk.syntax_highlight_id: Option<HighlightId>`, `cx.theme().syntax().resolve_runs(&[(Range, HighlightId)])` -> HighlightStyle; template `search/src/text_finder/delegate.rs:1395`. Merge with the match chip via `gpui::combine_highlights(a, b)` (drops empty ranges, tiles). `BufferSnapshot` + `Entity<Buffer>` are Send: read file info on main, `cx.background_spawn(...)` (AsyncWindowContext, `AppContext` trait) for the rest.
- PopoverMenu in tests: `PopoverMenuHandle::{toggle,is_deployed}` work after one render; but the menu takes focus via two `on_next_frame` hops, which only a platform frame request runs - `window.draw` x N does NOT, so keyboard-driving menu entries (SelectFirst/Confirm) in a test does not work. Test the pick handler directly (cfg(test) helper) and the open/close via the action.
- Editor `set_text` with identical text still emits `BufferEdited` (a subscription that ticks a checkbox fires).
- macOS `sed -i 's/..\n../'` fails; use python for multi-line edits.
