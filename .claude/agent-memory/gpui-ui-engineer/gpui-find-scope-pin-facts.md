---
name: gpui-find-scope-pin-facts
description: Verified modal pin / search-scope / open-files facts from zenith_search Find in Files M1a (fork c2f44cc209 on feat/search-parity)
metadata:
  type: project
---

- Modal pin = `ModalView::on_before_dismiss -> DismissDecision::Dismiss(!pinned || closing)` (`crates/workspace/src/modal_layer.rs:49`). `Dismiss(false)` also sets the layer's `dismiss_on_focus_lost`, so blur re-asks and stays open. Esc/confirm must set a `closing` flag before `cx.emit(DismissEvent)` or pinning blocks them. The layer's full-size `occlude()` overlay stays, so a pinned popup keeps the editor behind unclickable (needs an upstream non-occluding layer to fix).
- Re-invoking the open shortcut calls `toggle_modal` -> `hide_modal`; set `closing` on the active modal in `open()` first or a pinned popup refuses to toggle off.
- Project search: `SearchQuery::text/regex(..., match_full_paths, buffers)`; `buffers: Some(vec)` searches only those buffers (Open Files), `match_full_paths` prefixes globs with the worktree root name (Zed's search tab sets it iff >1 visible worktrees, `crates/search/src/project_search.rs:2184`). Module scope = glob `<root_name>` / `<root>/**/*.php` + match_full_paths only with several worktrees. `DeploySearch` has no open-files option.
- Open buffers: `workspace.items_of_type::<Editor>(cx)` + `.buffer().read(cx).as_singleton()`; capture at open (reading the workspace later risks a lease panic). Worktree name: `worktree.read(cx).root_name_str()`.
- Click-outside test: `cx.simulate_mouse_down/up(point(4,4), Left, Modifiers::none())` reaches the ModalLayer overlay in a VisualTestContext (inside the window).
- `PopoverMenu` + `ContextMenu::build` + `toggleable_entry(label, checked, IconPosition::Start, None, handler)` is the funnel template (also `zenith_search.rs` SE filter). `IconName::{Filter,Pin,Unpin}` exist. `Button::aria_role(gpui::Role::Tab)` works.
- rustfmt: run on copies of the whole src dir (mods must resolve); `zenith_search.rs` has pre-existing fmt diffs, only splice your own block.
