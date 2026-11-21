---
name: gpui-hover-card-facts
description: Verified fork facts for the hover card renderer (zenith_look::hover_card) and a shared-target worktree collision trap (2026-11-21)
metadata:
  type: reference
---

Fork worktree `~/GithubProjects/zed-hover` (feat/hover-card), 2026-11-21:

- Shared `CARGO_TARGET_DIR` across worktrees: a workspace crate with the same relative path can reuse ANOTHER worktree's artifact (editor saw `ZenithSettingsContent` with a `wordpress` field it doesn't have). Fix: `touch` the stale crate's source, rerun check. Seen on `settings_content`.
- `ToggleCodeActions` is `editor::actions::ToggleCodeActions` (editor.rs:14 `pub mod actions`; root re-export is pub(crate)). `Editor::toggle_code_actions(&action, window, cx)` is pub (code_actions.rs:7).
- `editor::hover_popover::hide_hover(&mut Editor, cx)` pub (hover_popover.rs:228); `hover_markdown_style(window, cx)` :1028; `SelectionEffects::default()` pub (editor.rs:1386); `select_anchor_ranges` selections_collection.rs:960.
- `CopyButton::new(id, message)` copy_button.rs:44 (uses use_keyed_state; RenderOnce). `ElevationIndex::ElevatedSurface.shadow(cx) -> Vec<BoxShadow>` elevation.rs:42; `.shadow(Vec<BoxShadow>)` styled. `Tooltip::for_action_title(title, &dyn Action)` tooltip.rs:58.
- IconName has XCircle, Warning, Info, Circle (no LightBulb/Hint).
- `cargo fmt -p zenith_look` reformats existing files differently from the committed style: don't run it on the crate; format only the new file or revert strays.
- Adding `markdown.workspace = true` to a zenith crate edits Cargo.lock (1 line) outside the crate.
