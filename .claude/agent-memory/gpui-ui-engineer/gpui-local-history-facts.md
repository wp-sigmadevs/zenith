---
name: gpui-local-history-facts
description: Verified fork facts for zenith_local_history C3 (history Item embedding FileDiffView, Store read path, ProjectPanel focus target); fork 9e6de83562 + uncommitted
metadata:
  type: reference
---

- `FileDiffView::new(old, new, Entity<BufferDiff>, project, Entity<Workspace>, window, cx)` is pub, `build_buffer_diff(&old,&new,&mut AsyncApp)` is pub (`git_ui_core/src/file_diff_view.rs:105,223`); its `editor`/`old_buffer` fields are private. Re-diff is a 250 ms debounce (`RECALCULATE_DIFF_DEBOUNCE`, private): tests `advance_clock(300ms)` + `run_until_parked`. An old buffer with no file shows breadcrumb "untitled <-> a.txt".
- `AsyncWindowContext` derefs to `AsyncApp`; its `AppContext::new` returns `Entity<T>` directly (not Result), so `cx.new(..)` works inside `cx.spawn_in`.
- Embedded editors: the Item's `focus_handle` = list handle; list div gets `key_context` + `menu::Select*/Confirm/Cancel` listeners only (editor Escape must not reach `menu::Cancel`). Same action key (`alt-shift-h`) on an open tab = activate + refocus list (dedupe via `workspace.items_of_type::<T>`), no extra keymap needed.
- Project-panel context-menu actions dispatch with the panel focused: pick `ProjectPanel::selected_entry_project_path` only if `panel.focus_handle(cx).contains_focused(window, cx)` and the entry is a file, else `workspace.active_item(cx)?.project_path(cx)`; override `Item::active_project_path` on the new item.
- Store reads: `Store` is not Sync; reads go through the capture owner task as `Job::List/Content` with a `oneshot` reply, answered in queue order. Open the buffer FIRST (opening records the "open" baseline), then send the list job, or the baseline is missing.
- Tests: `KeymapFile::load_panic_on_failure(json, cx)` rejects unknown action names (verifies zed_actions registration). Needs dev-deps `remote_connection` test-support (else E0004 Mock) and `fs`/`editor`/`workspace`/`project` test-support. `RelPath::from_unix_str("a.txt")?.into()` makes an `Arc<RelPath>`.
- Child test module trick: `#[cfg(test)] #[path = "history_view_tests.rs"] mod tests;` inside history_view.rs gives tests access to private fields; test names then contain `history_view`.
- Disk: a `cargo test -p zenith_local_history` build dropped free space 33 -> 28 GiB (30 GiB gate blocks reruns).

C4 (revert/copy, fork 58d3a3ee58, 2026-11-20):
- `Buffer::set_text` = one `edit(0..len)` = one transaction (`language/src/buffer.rs:2756`). Undo grouping: `TextBuffer` group_interval is 0 under test (`text.rs:226`), so tests do not merge edits unless `buffer.set_group_interval(..)`; real editing merges edits within the interval, so wrap a revert in `finalize_last_transaction()` before AND after (sabotage-proven, test sets the interval).
- Actions placed on the Item's ROOT div (`key_context("LocalHistoryView")` + `on_action`) work from the list and from the embedded editor; `cx.dispatch_action(..)` in tests reaches them from the focused list.
- `Store::record` skips a row whose blob equals the latest, so a pre-revert snapshot of an already-saved text adds no row. A `capture::capture(&buffer, "<source>", cx)` call with a new source string shows in the list via `source_name` (add a mapping); do not call it inside `buffer.update` (buffer is leased).
- `Button::tab_index` takes `impl Into<isize>`: use `0i16`, not `0`. `Tooltip::for_action_title(title, &Action)`. `cx.read_from_clipboard().and_then(|i| i.text())` in `VisualTestContext`.

C4 review round (fork 0aaf01fa8c, 2026-11-20):
- KEYMAP PRECEDENCE: a context-less binding has depth = context stack LENGTH (deepest) (`gpui/src/keymap.rs:274`), so it is tried before any contextful binding; unhandled actions fall through to the next binding. A `null` in a deeper context does NOT unbind it, and there is no default Tab traversal (focus_next is only called from action handlers). To beat base "tab": menu::SelectNext, bind in the FOCUSED element's own context (last in the stack, depth == len) and load later (zenith.json); `"A || B"` predicates work per slice.
- A button given `.track_focus(&own_handle)` ignores its `tab_index`/`tab_stop`: set `FocusHandle::tab_stop(bool)` on the handle (copy per render, `false` when disabled). `ButtonLike::aria_description`, `Button::key_binding(KeyBinding::for_action_in(..))` (auto aria-keyshortcuts). `ListItem` has no position-in-set; it already reports aria_selected with a role.
- `Buffer::diff(text, cx)` is line based (a one-line file is replaced whole) and `apply_diff` sets the diff's line ending; restore it with `set_line_ending`. Wrap in `start_transaction`/`end_transaction` + `finalize_last_transaction` both sides.
- Any test binary that loads `assets/keymaps/zenith.json` with `load_asset(..).expect` (zenith_search tests) needs stub `actions!` mods for new zenith_* actions defined in other crates.
- Test keymaps: `KeymapFile::load(json, cx)` returns SomeFailedToLoad with usable bindings; `include_str!("../../../assets/keymaps/...")` from crate src.

C5 (external changes + recover, fork 0aaf01fa8c + uncommitted, 2026-11-20):
- `WorktreeUpdatedEntries` fires for the editor's OWN save while the buffer is still dirty (arrives before `did_save`), so an external-change hook must defer dirty-buffer paths (`DIRTY_SETTLE` 2 s, tests `advance_clock(3s)`) or own saves get labelled external and the "save" row is lost to dedupe.
- `RelPath::from_unix_str` is NOT strict: it trims a leading `./` and trailing `/` and returns Borrowed; compare `rel.as_unix_str() == input` to reject them (`path/src/rel_path.rs:122`). It does reject `..`, `.`, `//`, absolute.
- `Fs::create_file` with `overwrite:false, ignore_if_exists:false` is exclusive (O_EXCL, also fails on a dangling symlink; FakeFs bails "already exists"). `FakeFs::metadata` of a dangling symlink is `Ok(None)`. Fs has no `block_test`; tests just `.await` (`write_new(..).await`).
- `Snapshot::is_path_ignored(rel)` falls back to the nearest scanned ancestor, so a gitignore pattern naming a DELETED file itself cannot be evaluated; only an ignored directory that still has an entry counts (`worktree.rs:2915`). `LocalWorktree::scan_complete()` is an owned future (`:1614`).
- A `&Store` (not Sync) may not live across an `.await` in the owner task: re-borrow from the owning `Option<Store>` after the await.
- `Buffer::Reloaded` only for clean buffers; `project.update` untrusted test: `project::trusted_worktrees::init(Default::default(), cx)` BEFORE `Project::test`, default.json has `trust_all_worktrees:false`; without the init `can_trust` is skipped (trusted).
- Picker modal: `window.spawn(cx, ..)` + `picker.downgrade().update_in(cx, ..)` for work that must outlive the modal; `render_footer` for a status line; `Picker::refresh` re-runs `update_matches`. Zero new actions needed: existing zed_actions `RecoverDeletedFiles` stub is registered by `workspace.register_action`; Tab in the Picker is `ConfirmCompletion` (no-op by default).
