---
name: gpui-agent-review-facts
description: Verified (read-only, uncompiled) facts for zenith_agent_review step C panel/status/chip, worktree zed-agent-review 99f90d59cf
metadata:
  type: reference
---

- Panel buttons must call handlers directly, not `window.dispatch_action`: a mouse click does not move focus, so the action would reach the focused editor (agent::Keep there keeps a hunk). Pattern: `type Handler = fn(&mut Panel, &mut Window, &mut Context<Panel>)` + set `selected` first.
- `ActionLog::changed_buffers` iterates a BTreeMap keyed by Entity (stable order); `DiffStats::single_file(diff.read(cx))` gives +/-. ActionLog has no events: observe it for live stats (`action_log.rs:1026,1064`).
- Title bar repaints on workspace notify (`title_bar.rs:495` observes the workspace); a global + deferred `workspace.update(|_, cx| cx.notify())` avoids an upstream hook.
- Zed agent keys: `AgentDiff` context `cmd-y` Keep, `cmd-alt-z` Reject, `shift-alt-y/z` Keep/RejectAll (`default-macos.json:230`); actions `agent_ui::{Keep,Reject,KeepAll,RejectAll}`.
- Free activation priority after 8-13 (zenith) = 14; debug builds panic on duplicates (`dock.rs:803`). `cmd-shift-0` is bound only in the image viewer context.
- zenith_search keymap tests load zenith.json with allow-partial-failure: no stub needed for new zenith_* actions there (2026-11-22).
- `AcpThread::title()` is None for stub sessions; tests call `set_provisional_title`.
