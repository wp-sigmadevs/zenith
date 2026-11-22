# 23 — Agent Review Queue (F5)

> **Status (2026-11-22):** 🟨 M1 + review fixes merged in fork `zenith` (`aa2247a2d2`, fixes `5960463a49`, `180d8b20cd`, keymap ⇧⌥R `162879fba2`); `zenith` @ `8ef52d743d`. Not seen in a running app.

## Goal

Every change an agent makes — via Zed Agent Panel, ACP agents, the IDE server (06), or a CLI agent writing files directly — lands in one review queue, backed by local-history checkpoints (05), so nothing is applied blind and everything is revertible.

## Parity checklist

- [ ] Capture sources: Agent Panel edits, IDE-server `open_diff`, external file writes during an active agent session (must)
- [ ] Checkpoint before each agent turn (local history label `agent:<session>:<turn>`) (must)
- [ ] Queue panel: grouped by session → turn → file, with +/− counts (must)
- [ ] Per hunk: accept / reject; per file; per turn ("revert everything this turn did") (must)
- [ ] Run inspections/tests on the pending set (21/07) (must)
- [ ] Annotate: why-comment from agent message linked to each turn (later)
- [ ] Policy: "auto-accept paths matching glob" (e.g. tests) (later)

## Architecture

- Crate `zenith_agent_review`, depends on `zenith_local_history`.
- Session tracking: session started by (a) Agent Panel thread start (*verify event*), (b) IDE server client connect, (c) 22 task start, (d) manual "Start agent session".
- External writes: worktree FS events during an active session → attribute to session; diff vs last checkpoint.
- Accept = mark reviewed (content stays); Reject = restore hunk from checkpoint via buffer edit (undoable).
- Zed already has an agent diff review UI — reuse/extend it for Agent Panel edits; queue unifies sources (*verify* reusability).

## UX

Right-stripe "Review" panel (or tab inside 22's Agents panel). Badge with pending count in title bar.

## Milestones

1. Sessions + checkpoints per turn (requires 05).
2. External-write capture + queue panel + file/turn revert.
3. Hunk-level accept/reject.
4. Run checks on pending set; policies.

## Risks

Attribution ambiguity when the user edits during an agent session — show "mixed" marker, never auto-revert user edits.

## Effort

1–2 weeks.

## M1 design (lead-engineer, 2026-11-22, verified read-only against fork `zenith` @ `769b620723`)

**Scope:** cross-thread review queue, per-turn local-history checkpoints with "Revert turn", live title-bar chip, status-bar item. Hunk-level review stays Zed's `AgentDiffPane` (`agent_ui/src/agent_diff.rs:51`, per-hunk Keep/Reject) — we open it, we don't rebuild it. All fork code: an LS/extension cannot see `AcpThread`/`ActionLog`.

**Zed APIs used:** `AcpThread::status()` / `is_waiting_for_confirmation()` / `action_log()` / `session_id()` / `title()` / `parent_session_id()` and `AcpThreadEvent::{StatusChanged, Stopped, ToolAuthorization*}` (`acp_thread.rs:3941-4586`; turn start = `StatusChanged` → Generating, `:7677-7698`; turn end = `Stopped`). `ActionLog` has no events (observe `notify`): `changed_buffers` `:1026`, `DiffStats::single_file` `:1064`, `keep_edits_in_range` `:641`, `reject_edits_in_ranges` `:712`, `keep_all_edits` `:896`, `reject_all_edits` `:924`. `BufferDiff::base_text` = pre-agent text. Threads reached with `cx.observe_new::<AcpThread>` — no upstream hook.

**Crates:**
1. `zenith_local_history`: `Job::Record` gets a label; labelled records skip the dedupe (`store.rs:203`); new `Store::labeled`, `pub fn checkpoint(buffer, text, label, cx) -> bool` (false for secret/too big/not local/off), `pub fn labeled_text(buffer, label, cx)`; source "Agent".
2. `zenith_title_bar`: `AgentChip` global (per project: running, review) → chip shows "Agents" or "1 running · review 2".
3. New `zenith_agent_review` (`zenith_agent_review.rs`, `queue.rs`, `checkpoint.rs`, `panel.rs`, `status.rs`, `tests.rs`); umbrella feature `agent_review`.

**Flow:** `observe_new::<AcpThread>` (skip subagents; weak handles; `cx.defer`, never `cx.entity().read`). Turn start ⇒ turn += 1, label `agent:<session>:<n>`, checkpoint current text of changed buffers; first agent edit of a file in turn n ⇒ checkpoint `diff.base_text` (none ⇒ "created"). Summary changes ⇒ update chip global, notify queue; status item repaints the workspace. Panel per thread (title, Running / Needs input / Review): files +N −M, Keep / Reject per file, Keep All / Reject All, Open diff (`AgentDiffPane::deploy`, in `window.defer`), Revert turn n (confirm; restores checkpoints as one undoable edit, then saves; warns it also undoes user edits made during that turn).

**Keys:** `secondary-shift-0` → `zenith_agent_review::ToggleFocus` in `zenith.json`.

**Upstream touches:** root `Cargo.toml` members + workspace dependency = 2/5. Settings key `zenith.agent_review.enabled` needs `settings_content` (core rebuild) — owner decision: add now or with the next batched settings change.

**Steps:** A label API + tests (rust-core-engineer) → B queue, turns, checkpoints, keep/reject/revert (agentic-integrations-engineer) → C panel, status item, chip (gpui-ui-engineer) → code-reviewer + performance + accessibility. Gates: `cargo test -p zenith_local_history`, `-p zenith_agent_review -p zenith_title_bar`, `-p zenith_search` (keymap), `cargo check -p zenith`, real-workspace open test.

**Tests:** labelled record not deduped; `labeled_text` round-trip; secret file refused; fake ACP thread edits a FakeFs file over two turns ⇒ both labels, Revert turn 2 restores turn 1 and undo brings turn 2 back; counts running 1 → review 1 → 0 after Keep All; real-workspace open + toggle panel without panic.

**Deferred:** external CLI-agent writes (M2), IDE `open_diff` (06), own hunk UI, turns across restarts, "mixed" detection, checks + policies (M4).

**Risks / unknowns:** whether ACP agents such as Claude Code write through client fs (else edits bypass `ActionLog`) — UNVERIFIED, check in step B; revert vs `ActionLog` user-edit rebase untested; recompute cost while edits stream; `agent_ui` merge churn.

**Effort:** ≈ 4–5 days (A 1, B 2, C 1.5).
