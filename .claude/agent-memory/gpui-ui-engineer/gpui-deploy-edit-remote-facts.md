---
name: gpui-deploy-edit-remote-facts
description: Verified fork facts for zenith_deploy M4a C3 (editable remote copy, prompts, release timing, toast in workspace actions); fork 69a59d8b6f, 2026-11-25
metadata:
  type: reference
---

- Test prompts: `VisualTestContext::has_pending_prompt()`, `pending_prompt() -> (msg, detail)`, `simulate_prompt_answer("<button label>")` (gpui test_context.rs:434); `Window::prompt` queues there with PromptBuilder::Default. Button list `&[PromptButton]` (`PromptButton::ok/cancel/new`).
- `Project::find_project_path` only searches VISIBLE worktrees: an `open_abs_path` file (invisible worktree) is not found. Find an open buffer by `project.opened_buffers(cx)` + file abs path instead.
- `observe_release` callbacks fire at the next effect flush, not at the drop: in tests add `cx.update(|_, _| ())` + `run_until_parked()` after closing a tab.
- A `Workspace::register_action` handler runs with the workspace leased: `WeakEntity<Workspace>::read_with/update` inside panics. Pre-capture the project (closure) and `cx.defer` the `show_toast`.
- `ServerStore` private fields (`copies`, `servers`) are readable from `panel.rs` (descendant of crate root).
- `Editor::should_serialize` is the `SerializableItem` trait method (`should_serialize(&EditorEvent::Saved)`); `set_should_serialize(bool, &App)`.
- Panel tests: real cache is written on smol's pool; `executor().allow_parking()` + poll loop (see `wait_for_editor`), mirror the cache file onto FakeFs with `insert_tree`. Save through `project.save_buffer(buffer, cx)`.
- `cargo fmt -p zenith_deploy` was safe here (only touched my files).
