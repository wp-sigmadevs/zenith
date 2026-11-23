# 22 — Agent Worktrees (F4) — config only

Owner decision 2026-11-23: shrink to the gaps upstream leaves. lead-engineer audit @ fork `f97b67b69b` (2026-11-23).

## Goal

Run several coding agents in parallel, each in its own git worktree. Upstream Zed now does most of this; Zenith adds `tasks.json` recipes and one guide, no fork code.

## Upstream coverage (audit @ `f97b67b69b`)

| Item | Status | Where |
|---|---|---|
| Create worktree from base | partly | worktree picker, detached HEAD (`zed_actions/src/lib.rs:305-327`, `git_ui_core/src/worktree_service.rs:739`), dir `git.worktree_directory` (`settings_content/src/project.rs:706`); agent tool `create_thread{prompt, agent, use_new_worktree, worktree_name, base_ref}` (`agent/src/tools/create_thread_tool.rs:40-96`). Gap: no `agent/<slug>` branch, no single dialog |
| Start agent in worktree | covered | ACP Claude/Codex/Gemini via ACP Registry (`docs/src/ai/external-agents.md:47-51`); CLI agents as Terminal Threads (`agent.terminal_init_command`, `settings_content/src/agent.rs:370`) |
| Status list | covered | Threads Sidebar grouped by project incl. linked worktrees, Running/Waiting/Completed/Error, ± lines (`sidebar/src/sidebar.rs:1878-1915`, `:6461`). No elapsed time: accepted |
| Notify | covered | `agent.notify_when_agent_waiting`, `play_sound_when_agent_done` (`settings_content/src/agent.rs:326,330`); Claude Code needs `preferredNotifChannel = terminal_bell` |
| Diff vs base, tests | covered | BranchDiff "Changes since {branch}" (`git_ui/src/branch_diff.rs:44-49`); worktree is a full workspace |
| Merge / PR | PR covered, merge gap | `git::CreatePullRequest` (`git_ui/src/git_ui.rs:167`); no merge/rebase action → recipe; conflicts and rebase belong to plan 10 |
| Discard | covered | thread archive saves to `refs/archived-worktrees/<id>` and removes (`agent_ui/src/thread_worktree_archive.rs`); picker Delete/ForceDeleteWorktree |
| Env/setup copy | covered by hook | `TaskHook::CreateWorktree` (`task/src/task_template.rs:95-98`), run for trusted worktrees only (`workspace/src/tasks.rs:241-252`); `ZED_MAIN_GIT_WORKTREE` (`task/src/task.rs:186`) |
| Port isolation | gap (later) | Valet recipe |
| Cost/tokens | covered | ACP UsageUpdate (`acp_thread/src/acp_thread.rs:5189`) |

## Gaps → recipes (global `~/.config/zenith/tasks.json`)

- [ ] Setup hook (`hooks: ["create_worktree"]`, cwd `$ZED_WORKTREE_ROOT`): copy `.env` from `$ZED_MAIN_GIT_WORKTREE`; `composer install` if `composer.json`; `npm ci` if `package-lock.json`. Install, never symlink `vendor/`/`node_modules/` (two worktrees would share state) (must)
- [ ] Optional branch hook: `git switch -c agent/<worktree dir name>` (should)
- [ ] "Worktree: squash into base" manual task: abort if `git status --porcelain` is non-empty in the worktree; else `git -C $ZED_MAIN_GIT_WORKTREE merge --squash <worktree HEAD>`; never commits (must)
- [ ] Optional Valet hook: `valet link <worktree dir name>` → `<name>.test` (later)
- [ ] Guide `docs/guides/agent-worktrees.md` with the recipes + Claude Code `preferredNotifChannel = terminal_bell`; router row in `docs/map/DOCS.md`

Kill rule: drop each recipe when upstream ships it.

## Not built (upstream has it)

`zenith_agents` crate, "Agents" panel, `.zed/zenith-agents.json`, CLI status heuristics, Claude Code hook → IDE server path.

## M2 (deferred, owner request only)

"New Agent Task" modal (prompt + agent + base → CreateWorktree + thread). Crate `zenith_agent_tasks`; 2 upstream lines (workspace members + dependency). *verify*: whether `AgentPanel::create_thread_with_options` is `pub`. A2 candidate instead of the branch recipe: a `git.worktree_branch_prefix` setting upstream.

## Safety

Never auto-merge or auto-commit; hooks run only in trusted worktrees (upstream gate); delete the worktree right after merge (owner 2026-11-22). The squash recipe gets a security review (shell quoting, cwd) before it ships.

## Tests

No Rust. `jq empty` on the recipe JSON. Running-app checklist: create worktree → `.env` present + deps installed; squash task refuses a dirty tree and stages changes on a clean one; archive removes the worktree and restore brings it back.

## Open (*verify*)

- Do `ZED_*` task variables expand inside `sh -c` strings or only in command/args/cwd? Test in the app, or write recipes as command + args.
- Does plan 23 agent review see edits from threads in a separate worktree workspace?

## Effort

~0.5 day.
