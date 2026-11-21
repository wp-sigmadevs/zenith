---
name: hover-card-facts
description: Verified editor hover-popover internals and hook/test recipe for the Zenith hover card (fork feat/hover-card)
metadata:
  type: project
---

Fork worktree ../zed-hover, branch feat/hover-card @ 16b14eb65b (base zenith e13b1f697d).
- HoverState fields/InfoPopover/DiagnosticPopover: crates/editor/src/hover_popover.rs (fields private; a child module `hover_popover/zenith_card.rs` can read them, so no upstream visibility edits).
- Debugger hover = InfoPopover.debugger_hover (private Option<Entity<DebuggerHoverView>>).
- Settings use inventory (`#[derive(RegisterSetting)]`): no init call needed; read via `T::get_global(cx)`.
- rustfmt expands `if let .. { return ..; }` to 3 lines; one-line hook is deliberate (owner's count gate).
- macOS `sed -i` needs `''`; use Edit/python. A post-write hook rustfmt's edited .rs files.
- Concurrent agents share ~/GithubProjects/zed/target; a `cargo sweep` by anyone mid-build gives "No such file" rlib/sccache errors: just rerun.
- Test recipe: EditorLspTestContext + hover_at + advance_clock + requests.next() (see zenith_card.rs tests).
