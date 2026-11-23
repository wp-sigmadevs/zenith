# 43 — AI Terminal

Status: ⏸ ON HOLD (owner 2026-11-23, "belay"). Plan approved; do not build until the owner resumes it. Upstream audited at fork `zenith` @ `e8ad13ff41` by lead-engineer. Anything not checked in source is marked *verify*.

## Goal

A terminal-first AI workspace inside Zenith. It should feel like iTerm + oh-my-zsh, and run Claude Code, Codex, Gemini CLI (now Antigravity CLI `agy`, *verify*) and the Zed Agent side by side. The owner's Supercharger guards are on by default and apply to every agent. The best perks from other tools come along (image paste, clickable paths, status, notifications). Build only what upstream does not already ship.

## Owner decisions

| # | Decision | Status |
|---|---|---|
| 1 | 43 **depends on** plan 06 (does not absorb it). Plan 06 serves the whole IDE and is its own crate; 43 M1 only pulls 06's Claude Code adapter to the front | approved |
| 2 | Terminal agents run as upstream **Terminal Threads** (Threads Sidebar), not a new panel | approved |
| 3 | Supercharger: **offer, don't auto-install**. First run offers one-click "Install Supercharger (recommended)", safe mode preselected; a user's own install is never touched; updates only for Zenith-made installs | approved 2026-11-23 |
| 4 | Cross-agent guards = config writers (each CLI's own hook file) + Zed Agent `tool_permissions`. No interception in Zenith code in v1 | approved |
| 5 | Inline terminal images = research spike + upstream PR, not fork code | approved |
| 6 | Zenith does not install oh-my-zsh or touch `~/.zshrc`; it ships font + theme + keys only | approved |
| 7 | Gemini: support **both** `agy` and `gemini`; the launcher uses whichever is installed (`agy` first); both configurable | approved 2026-11-23 |
| 8 | Supercharger pin = **release tag + sha256** in `vendor/supercharger/PIN`; owner tags each release | approved 2026-11-23 |
| 9 | Build order: bundle check of merged work first → M2 status → M3 launcher → plan 06 (M1) → M4 → M5 spike | approved 2026-11-23 |

## Upstream audit (@ `e8ad13ff41`)

| Feature | Status | Evidence |
|---|---|---|
| CLI agents in sidebar threads | covered | Terminal Threads: `NewTerminalThread` (`agent_ui/src/agent_panel.rs:483-495`), pub `AgentPanel::new_terminal` (`:2083`), `terminals()` (`:3481`), `activate_terminal` (`:2391`); `docs/src/ai/terminal-threads.md` |
| Auto-run a CLI in a new thread | partly | one global `agent.terminal_init_command` (`settings_content/src/agent.rs:370`); gap: per-agent / per-launch command |
| Status: running | partly | sidebar shows the CLI's leading title glyph (`sidebar/src/sidebar.rs:231` `split_leading_icon_char`) |
| Status: needs attention | covered | `Event::Bell` (`terminal/src/terminal.rs:667,1686`) → `mark_terminal_notification` (`agent_panel.rs:2345,2751-2781`): popup, sound, dot, click to focus; `agent.notify_when_agent_waiting`, `play_sound_when_agent_done` (`settings_content/src/agent.rs:326,330`). Claude Code needs `preferredNotifChannel: terminal_bell` |
| Status: waiting vs done vs error | gap | bell can't tell them apart; ACP threads have 4 states (`sidebar.rs:8327-8334`), Terminal Threads don't |
| Known agent CLIs | covered (telemetry only) | `KNOWN_TERMINAL_AGENT_COMMANDS`: `claude`, `codex`, `gemini`, `agy`, `opencode` (`agent_panel.rs:176-194`) |
| ACP agents with model, resume, cost | covered | ACP Registry (`docs/src/ai/external-agents.md`); `supports_load_session` / `resume_session` (`acp_thread/src/connection.rs:117,168`); cost `acp_thread.rs:5005`, `UsageUpdate` `:5189` |
| Cost for CLI sessions | gap (skip) | the CLI's own status line shows it |
| Image paste into a CLI | covered | clipboard image → ctrl-v forwarded (`terminal_view/src/terminal_view.rs:991-992`); clipboard paths inserted (`:994-995`) |
| Drag files/images into a terminal | covered | `ExternalPaths` drop (`terminal_view.rs:1727`) |
| Clickable `file:line` | covered | `terminal_view/src/terminal_path_like_target.rs`, `alacritty/hyperlinks.rs`, `path_hyperlink_regexes` (`settings_content/src/terminal.rs:104`) |
| Split panes and tabs | covered | split menu (`terminal_panel.rs:183-199`); no iTerm `cmd-d` default |
| Font, fallbacks, Option as Meta, bell | covered (config) | `settings_content/src/terminal.rs:125,132,160,238` |
| Nerd Font glyphs | gap (config) | `assets/fonts` has ibm-plex-sans, jetbrains-mono, lilex only; plan 38 owns fonts |
| OSC 133 prompt marks / command blocks | gap | no `PromptMark`; alacritty fork rev `4c12966` (`Cargo.toml:599`); plan 38 upstream PR |
| Inline images (kitty / iTerm2 OSC 1337 / sixel) | gap | nothing in `crates/terminal*` |
| AI command generation in a terminal | covered | `agent_ui/src/terminal_inline_assistant.rs` |
| Claude Code IDE link (lockfile + WebSocket) | gap | no `claude/ide` / `CLAUDE_CODE_SSE_PORT` in `crates/`; plan 06 ⬜ |
| Guards for Zed Agent | covered (Zed Agent only) | `agent.tool_permissions` `always_deny` / `always_confirm` / `always_allow` (`settings_content/src/agent.rs:413,1085`), sandbox (`docs/src/ai/sandboxing.md`, `tool-permissions.md`). Not applied to Terminal Threads or External Agents |
| Guards for ACP agents | gap | every request goes through `AcpThread::request_tool_call_authorization_with_id` (`acp_thread.rs:6894`); no policy hook |
| Terminal env marker | fact | `insert_zed_terminal_env` sets `TERM_PROGRAM=zed`, `ZED_TERM=true` (`terminal/src/terminal.rs:649-658`), from `project/src/terminals.rs:647` |

External facts (vendor docs, 2026-11-23):

- **Claude Code IDE protocol** (claudecode.nvim `PROTOCOL.md`, reverse-engineered, *verify* against the current CLI): lockfile `~/.claude/ide/<port>.lock` with `pid`, `workspaceFolders`, `ideName`, `transport: "ws"`, `authToken`; env `CLAUDE_CODE_SSE_PORT`, `ENABLE_IDE_INTEGRATION`; auth header `x-claude-code-ide-authorization`. Tools: `openFile`, `openDiff`, `getCurrentSelection`, `getLatestSelection`, `getOpenEditors`, `getWorkspaceFolders`, `getDiagnostics`, `checkDocumentDirty`, `saveDocument`, `close_tab`, `closeAllDiffTabs`, `executeCode`. Notifications: `selection_changed`, `at_mentioned`.
- **Claude Code hooks** (code.claude.com/docs/en/hooks): `PreToolUse`, `PermissionRequest`, `Notification` (`permission_prompt`, `idle_prompt`, `agent_needs_input`, `agent_completed`), `Stop`, `StopFailure`, `UserPromptSubmit`, `SessionStart`, `SessionEnd`; hooks can be `type: "http"`; project-level `disableAllHooks: true` switches off user-level hooks.
- **Codex hooks** (learn.chatgpt.com/docs/hooks): `~/.codex/hooks.json`, `.codex/hooks.json` (trusted projects only) or `[hooks]` in `config.toml`; `PreToolUse`, `PermissionRequest`, `Stop`; same deny shape as Claude Code (`hookSpecificOutput.permissionDecision: "deny"` or exit 2).
- **Gemini CLI hooks** (geminicli.com/docs/hooks): `~/.gemini/settings.json`; `BeforeTool`, `AfterAgent`, `Notification`; deny = exit 2 or `{"decision":"deny"}`. The site says Gemini CLI was replaced by Antigravity CLI on 2026-06-18 (*verify*; upstream already lists `agy`).
- **Supercharger** (github.com/smrafiz/claude-supercharger, MIT, 4.4.8): `install.sh --mode safe|full --roles <r>` (non-interactive) writes hooks into `~/.claude/settings.json` and a block into `~/.claude/CLAUDE.md`; state in `~/.claude/supercharger/`; `uninstall.sh` restores a backup; `tools/update.sh`; `SUPERCHARGER_NO_UPDATE_CHECK=1`. Needs bash 3.2+, Python 3.7+, `jq`. Claude Code only. GitHub shows release v4.4.8; the audit saw no tag in the clone (*verify*; pin by tag or commit sha + sha256).

## Buckets (plan 16 A3)

| Sub-feature | Bucket | Why |
|---|---|---|
| Claude Code IDE link | fork crate (plan 06 `zenith_ide_server`) | needs live editor state and a diff `Item`; an LS or extension can't host the WebSocket server |
| Agent status + notification | fork crate + hook script | must find the right terminal entity and emit its bell |
| Session launcher | fork crate | needs `AgentPanel` |
| Supercharger bundle / install / update | fork crate | first-run notice, app-bundled files |
| Cross-agent guard adapter | config writer in the fork crate + shim scripts | each CLI has native hooks; Zed Agent has `tool_permissions` |
| iTerm look (font, theme, keys) | config: plan 38 + `zenith.json` | no code |
| Inline images | upstream PR | alacritty parsing + terminal grid renderer |
| Image paste, `file:line`, splits | upstream covered | — |

## Crates

- **`zenith_ai_terminal`** (new, GPL-3.0-or-later, Cargo feature `ai_terminal` of `zenith`). Depends on `agent_ui`, `terminal`, `terminal_view`, `workspace`, `settings`, `paths`, `rust-embed` (*verify* workspace version), `serde_json`. Modules: `zenith_ai_terminal.rs` (init, actions, settings), `status.rs` (socket listener, registry, pid → terminal), `status_item.rs`, `launcher.rs`, `supercharger.rs` (detect, extract, install, update), `adapter.rs` (Codex / Gemini / Zed Agent writers), `vendor/supercharger/` (pinned copy + MIT `LICENSE`), `scripts/zenith-agent-hook`, `scripts/zenith-guard-shim`.
- **`zenith_ide_server`**: owned by plan 06.
- Settings content: `ZenithAiTerminalSettingsContent` in `crates/settings_content/src/zenith.rs` (Zenith-owned file).
- `zenith_core` does not exist at this sha; use `smol::process` / `util::command` directly until a second user appears.

## Milestones

### M1 — Claude Code IDE link (= plan 06, reordered)

- Plan 06 builds its Claude Code adapter first (its M4), then generic MCP: `~/.claude/ide/<port>.lock` WebSocket server with `getCurrentSelection`, `getOpenEditors`, `getWorkspaceFolders`, `getDiagnostics`, `openFile`, `openDiff`, and a `selection_changed` push. Lockfile `ideName: "Zenith"`.
- 43 adds only a "Claude Code: connected" state to the M2 status item.
- Auto-connect: without `CLAUDE_CODE_SSE_PORT` in the terminal env the user runs `/ide` once, or sets Claude's `autoConnectIde` (*verify* key). A per-window env var needs window context in `insert_zed_terminal_env` (`terminal.rs:649`), which it lacks; plan 06 decides.
- Tests: plan 06's, plus lockfile mode 0600 and removal on window close.
- App exit check: in a Zenith terminal `claude` → `/ide` lists "Zenith" → select text → Claude sees it → ask for an edit → diff opens in Zenith → accept writes the file.
- Effort: plan 06 (2–3 wk) + 0.5 d.

### M2 — Agent status on terminals + notification

- A Zenith-shipped hook `zenith-agent-hook <agent>` is registered in each CLI's hook config: Claude `Notification`, `Stop`, `StopFailure`, `UserPromptSubmit`, `SessionEnd`; Codex `PermissionRequest`, `Stop`, `UserPromptSubmit`; Gemini / agy `Notification`, `AfterAgent`, `BeforeAgent`.
- The script pipes stdin to `curl -s --max-time 1 --unix-socket "$SOCK" --data-binary @- http://zenith/status`, always exits 0, and does nothing when the socket is missing (harmless outside Zenith).
- Zenith listens on `paths::data_dir()/run/agent.sock` (0700 dir); reads peer pid + uid (macOS `LOCAL_PEERPID`, Linux `SO_PEERCRED`, *verify* `libc` constants) and rejects other uids; walks the peer's ancestor pids in the background (`sysinfo`); matches them against `Terminal::pid()` (`terminal.rs:3163`) of every `TerminalView`, collected by `cx.observe_new::<TerminalView>` (no upstream line).
- States per terminal: `Running` (prompt submitted), `Waiting` (permission / input), `Done` (Stop), `Error` (StopFailure). On Waiting / Done / Error, Zenith emits `terminal::Event::Bell` so upstream's popup, sound, sidebar dot and click-to-focus are reused (*verify* emitting from another crate; dedupe against a real BEL within 1 s).
- Status-bar item "Agents": counts per state; its menu lists sessions with a state word + icon; picking one activates the terminal.
- Not built: four-state badges on tabs / sidebar rows (needs render hooks; A2 candidate "terminal attention kind").
- Upstream hooks: 2 (Cargo members + workspace dependency, shared by all 43 milestones).
- Tests: payload parser (allowlisted fields, > 64 KiB dropped); pid-chain matcher on fake process tables; `#[gpui::test]` Waiting → one bell, foreign uid rejected; `bash -n` / `shellcheck` on the script.
- App exit check: two Claude Terminal Threads, a task in one, switch away → permission prompt raises "Claude is waiting" and the item shows 1 waiting → click focuses the right terminal; finish shows "done"; killing `claude` leaves no stuck "running".
- Effort: ~4 d.

### M3 — Session launcher

- Actions `zenith_ai_terminal::NewClaudeSession`, `NewCodexSession`, `NewGeminiSession`, `ResumeAgentSession` (picker: agent × new / continue last / pick session) + a "New agent session" split button in the status item.
- How: `AgentPanel::new_terminal` → wait for `AgentPanelEvent::EntryChanged` (`agent_panel.rs:5124`) → new id from `terminals()` → send the command via `Terminal::start_init_command_startup_handshake` + `write_init_command_after_startup` (`terminal.rs:2219,2286`), the same path upstream uses (`agent_panel.rs:2248-2275`).
- Settings `"zenith.ai_terminal.agents": [{ "id", "label", "command", "resume", "continue", "model_flag" }]`; defaults `claude` / `--resume` / `--continue` / `--model`, `codex` / `codex resume` / `--model`, `gemini` or `agy` (*verify* all flags). Optional model picker from a static per-agent list; no discovery. No cost display (ACP threads have it; CLIs show their own).
- Risk: `new_terminal` also runs the global `terminal_init_command`; the launcher warns when it is set. Fallback if the event race is flaky: one appended block in `agent_panel.rs` adding `pub fn new_terminal_with_command` (upstream touch 3; A2 PR).
- Tests: settings defaults; command building; `#[gpui::test]` with upstream's terminal spawn gate if reachable (*verify*), else a unit test on command building.
- App exit check: palette "New Claude Session" opens a Terminal Thread running `claude`; "Resume agent session" → Codex opens `codex resume`; keys from `zenith.json` work.
- Effort: ~3 d.

### M4a — Bundled Supercharger: detect, install, update

- Vendored pinned copy (tag or commit sha + sha256 in `vendor/supercharger/PIN`), embedded with `rust-embed` (no `script/bundle-mac` edits).
- First run detects an existing install (`~/.claude/supercharger/` + version file, *verify* name). Notification: "Install Supercharger (safe | full)", "Not now", "Never". Install runs the bundled `install.sh --mode <m> --roles developer` in the background.
- Update offered only when the embedded version is newer **and** `installed.json` says Zenith installed it **and** its hook entries are unchanged (hash). Uninstall runs the bundled `uninstall.sh`.
- Status-item row: "Guards: Supercharger 4.4.8 (user install)".
- Tests on a temp HOME: none / user install / Zenith install / newer user install (never downgrade); extraction only under `data_dir()/supercharger/<ver>/`; pin mismatch refuses; process runs with HOME = temp dir.
- App exit check: on a clean macOS user, Install → `claude` → a destructive test command (e.g. recursive delete of a temp dir) is blocked by Supercharger. On the owner's machine: "user install" shown, nothing written.
- Effort: ~1 wk.

### M4b — Cross-agent guard adapter

- **Codex**: Zenith-managed `PreToolUse` entries in `~/.codex/hooks.json` → `zenith-guard-shim codex <supercharger-script>`. The shim (Python 3, already required by Supercharger) rewrites Codex stdin to Claude shape (`shell` → `Bash`, `apply_patch` → `Edit`; *verify* field names), runs the Supercharger script and passes the deny through.
- **Gemini / agy**: `BeforeTool` entries in `~/.gemini/settings.json`; shim maps `run_shell_command` → `Bash`, `write_file` / `replace` → `Write` / `Edit` (*verify*), deny → `{"decision":"deny"}`.
- **Zed Agent**: Supercharger's command-guard patterns (needs a data file, *verify*; else a Zenith list) → `agent.tool_permissions.tools.terminal.always_deny` via `update_settings_file`. Regex-only and weaker; the UI says so.
- **ACP External Agents**: Claude Agent / codex-acp may load the CLIs' own hooks (*verify*); the launcher marks an agent "unguarded" when not. A Zenith policy hook at `acp_thread.rs:6894` is deferred (A2 "permission policy provider").
- All writers: backup first, atomic write, keep file mode, touch only Zenith-managed entries (tag key or command-path match, *verify* per format), toggle per agent.
- Tests: shim golden tests (Codex / Gemini payload → Claude shape → deny passes through); writer idempotent and keeps user entries; `jq empty` on output.
- App exit check: the destructive test command is blocked in Codex and Gemini with Supercharger's reason; Zed Agent asks to deny/confirm; toggle off removes Zenith entries and keeps the user's.
- Effort: ~1 wk.

### M4c — Guard settings

- `"zenith.ai_terminal.supercharger": { "manage": "detect" | "zenith" | "off", "mode": "safe" | "full", "agents": { "codex": true, "gemini": true, "zed_agent": true } }`.
- Per-guard switches only if Supercharger has its own per-guard config (*verify* `docs/HOOKS.md`); until then mode + "Open Supercharger folder". Settings UI rides plan 29; v1 is JSON + palette actions.
- Effort: 1–2 d.

### M5 — Inline images (spike)

- 2-day spike: does the fork's alacritty `osc_dispatch` pass OSC 1337 / kitty APC through, and how would `terminal_element` paint an image over a cell range? Output: an upstream issue / PR proposal, no fork code. Claude Code and Codex already take images via paste and paths.

### Look and perks (config, rides plan 38)

- Symbols Nerd Font via `terminal.font_fallbacks` in `zenith_look` (licence and size *verify*); Driftwood ANSI palette audit.
- iTerm keys in `zenith.json` (context `Terminal`): `cmd-d` split right, `cmd-shift-d` split down, `cmd-[` / `cmd-]` pane focus, `cmd-shift-enter` zoom (*verify* action names).
- Guide `docs/guides/ai-terminal.md`: oh-my-zsh / p10k stay the user's own shell setup.
- Effort: 1 d beyond plan 38.

## Perks from other tools

| Perk | From | Upstream | Zenith |
|---|---|---|---|
| Parallel agents in worktrees | Conductor, Cursor | covered | plan 22 recipes |
| Session switcher | OpenCode, Conductor | covered (`sidebar/src/thread_switcher.rs`) | reuse |
| Needs-attention notifications | Conductor, iTerm triggers | covered (bell) | M2: waiting / done / error |
| Image paste / drag | Warp, Cursor | covered | — |
| Clickable `file:line` | iTerm | covered | — |
| Natural language → command | Warp | covered (terminal inline assistant) | — |
| Split panes / tabs | iTerm | covered | iTerm keys |
| Diff review of agent edits | Cursor, Conductor | ACP / Zed Agent covered; CLI gap | M1 `openDiff`, plan 23 |
| Selection / @-context to CLI | Cursor, Claude IDE | gap | M1 |
| Checkpoints | Cursor | Zed Agent covered; CLI gap | plan 05 local history |
| Command blocks / jump to prompt | Warp, iTerm | gap | plan 38 PR |
| Inline images | iTerm, kitty | gap | M5 spike |
| Cost per session | OpenCode, Conductor | ACP covered | CLI: skip |
| Broadcast input, hotkey window | iTerm | gap | not building |

## Upstream touches

| File | Where | Why |
|---|---|---|
| `Cargo.toml` | `members` | `crates/zenith_ai_terminal` |
| `Cargo.toml` | `[workspace.dependencies]` | `zenith_ai_terminal` |
| `crates/agent_ui/src/agent_panel.rs` | appended block, only if the M3 race fails | `new_terminal_with_command` |

Total 2/5 (3/5 worst case). Zenith-owned files not counted: `crates/zenith/Cargo.toml`, `crates/settings_content/src/zenith.rs`, `assets/keymaps/zenith.json`.

Plan 16 A2 candidates: per-launch Terminal Thread command; terminal attention kind (waiting / done / error); ACP permission policy provider; inline image protocol; OSC 133 (already listed).

## Security (security-engineer reviews each chunk)

1. **IDE server (plan 06)**: 127.0.0.1 only; random 32-byte token per window; lockfile 0600, deleted on close. **Reject any WebSocket upgrade with an `Origin` header or without the auth header** (the VS Code Claude Code extension had a cross-site WebSocket hole fixed in 2025, CVE-2025-52882, *verify*). `executeCode` / `run_task` off by default.
2. **Status socket**: Unix socket in a 0700 dir; peer uid must equal ours; payload ≤ 64 KiB; only allowlisted fields parsed (`hook_event_name`, `notification_type`, `tool_name`, `session_id`), `tool_input` and messages dropped unread; nothing logged to disk, executed or rendered as markup. A same-user process can fake a status: accepted (cosmetic).
3. **Status hook script**: fail-open (never blocks an agent), no `eval`, 1 s timeout, socket path fixed at install. Supercharger guards stay fail-closed.
4. **Writing into `~/.claude`, `~/.codex`, `~/.gemini`**: only after an explicit click; backup; atomic write; keep mode; never overwrite a user-managed or newer Supercharger; no network (`install.sh` runs from the embedded pinned copy, sha256 checked before extraction); `SUPERCHARGER_NO_UPDATE_CHECK=1` for Zenith-managed installs (*verify*).
5. **Guard bypass**: a project `.claude/settings.json` with `disableAllHooks: true` overrides user hooks; Zenith reads it (no exec) on project open and shows "Guards OFF in this project". `--settings '{"disableAllHooks":true}'` can't be detected (documented). Agents editing hook files: Supercharger's self-modification guard + Zenith re-hashes managed entries at startup and warns. Codex project hooks need trusted projects; Zenith writes user-level entries. Zed Agent translation labelled weaker; ACP agents labelled if unguarded.
6. **Supply chain**: review the vendored diff (`hooks/`) at each pin bump; MIT `LICENSE` kept beside it and listed on the About / licences page.
7. **Secrets**: no tokens in argv; the IDE token lives only in the lockfile; no Keychain needed.

## Performance (plan 18: ≤ 4 ms main thread per Zenith span)

- Socket accept, parse and pid walk on `background_spawn`; one main-thread `update` per event (< 0.5 ms target), coalesced per terminal (latest wins, ≥ 100 ms apart).
- Terminal registry holds `WeakEntity` + pid only; no per-frame work.
- Startup: no process spawn, no network; Supercharger detection reads one file in the background after first frame.
- Embedded Supercharger adds its size to the binary (*verify*, expected < 2 MB). Spans via `tracing`.

## Accessibility

- Every action in the command palette (`zenith_ai_terminal::*`) and bindable in `zenith.json`; all hidden when `disable_ai` is set (respect `filter_disabled_ai_bindings`, fork-findings).
- State shown as icon **and** word, never colour alone; tooltip carries the full text. Notifications reuse upstream focusable popups. Status-item menu works by keyboard. AccessKit labels on the item and rows (*verify* gpui support at this sha).

## Risks

- **M3 event race** on churny upstream `agent_ui` code; fallback = appended block.
- **Moving protocols**: unofficial Claude IDE protocol; Gemini → Antigravity; Codex hook fields. Thin adapters, one module each.
- **Double notification** if Claude still sends `terminal_bell` (1 s dedupe).
- **pid mapping** fails inside tmux / ssh: no status, no harm.
- **Owner's machine already has Supercharger**: the detect path must never write there.
- **Merge cost**: low (2 upstream lines); `agent_ui` pub API is the churn point.

## Open questions (*verify*)

1. Claude Code: connects without `CLAUDE_CODE_SSE_PORT` (`/ide`, `autoConnectIde`)? Does `TERM_PROGRAM=zed` change Claude Code behaviour or text?
2. Do the Claude Agent ACP adapter and codex-acp load the user's native hooks?
3. Codex / Gemini / agy tool names and `tool_input` fields for the shim; resume and model flags.
4. Supercharger: version file path, per-guard config, a pattern data file for the Zed Agent translation, idempotent re-install.
5. Can `terminal::Event::Bell` be emitted from another crate? Dedupe window testable in gpui?
6. `LOCAL_PEERPID` / `SO_PEERCRED` via `libc` at the workspace version.
7. Nerd Font licence and size; iTerm action names.
8. Existing upstream issue for kitty / iTerm2 image protocol?

## Build order (lead-engineer)

| Chunk | Check | Reviewers |
|---|---|---|
| 1. plan 06, Claude Code adapter first | `cargo check -p zenith_ide_server`, `cargo check -p zenith` | security |
| 2. crate skeleton + settings + actions | `cargo check -p zenith` | — |
| 3. M2 status | `cargo test -p zenith_ai_terminal`; `shellcheck` | security, performance, accessibility |
| 4. M3 launcher | `cargo test -p zenith_ai_terminal`; `cargo test -p zenith_search` after the `zenith.json` edit | accessibility |
| 5. M4a | `cargo test -p zenith_ai_terminal` | security |
| 6. M4b | shim golden tests; `jq empty` | security |
| 7. look keys | `cargo test -p zenith_search` | — |

Related doc fixes when building starts: plan 06 (Claude Code adapter first, Origin rejection, protocol facts above, `CLAUDE_CODE_SSE_PORT` decision); plan 38 (agent CLIs → plan 43); plan 16 A2 (4 candidates); plan 22 ("Claude Code hook → IDE server path" is now 43 M2 via the status socket).

## Effort

| Milestone | Effort |
|---|---|
| M1 | plan 06 + 0.5 d |
| M2 | 4 d |
| M3 | 3 d |
| M4a | 1 wk |
| M4b | 1 wk |
| M4c | 1–2 d |
| M5 | 2 d spike |
| Look | 1 d |

Total ≈ 4 weeks on top of plan 06.
