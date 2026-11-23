# 16 — Upstream Contributions & Extension-First Strategy (A2, A3)

## Goal

Keep the fork as small as possible: (a) push generic hooks into upstream Zed, (b) build anything possible as a Zed extension instead of fork code.

## A2 — Upstream contributions

Candidate PRs to zed-industries/zed (each generic, useful beyond Zenith):

| Hook | Lets Zenith | Replaces fork patch in |
|---|---|---|
| Panel registration API usable from an init fn (no edits to `zed.rs`) | register panels from our crates | 02 |
| Title bar slot/extension points (left/right item providers) | add toolbar widgets without copying `title_bar` | 14 |
| Dock "stripe" rendering option (vertical icon bars) | stripes without workspace patch | 14 |
| Buffer pre-save / post-save + pre-agent-edit events | local history checkpoints | 05, 23 |
| Terminal link/path rewriter hook | container → host paths | 11 |
| Gutter decoration provider for custom runnables | HTTP ▶, test ✓/✗ | 07, 08 |
| Terminal OSC 133 prompt marks (`TerminalBackendEvent::PromptMark`, scroll to prev/next prompt) | jump-to-prompt, command blocks | 38 |
| "Notification shown" observer in `workspace/src/notifications.rs` | notifications timeline | 36 |

Process:
1. Check Zed's contribution guide + open issues/discussions for each hook (maybe already requested).
2. Open a discussion first; small PRs; tests included.
3. Until merged, keep the patch in our fork isolated in one commit per hook (`feat(<crate>): hook ...`; the commit hook rejects `zenith(...)`) so it can be dropped cleanly once upstream lands.
4. Track in table below.

| Hook | Issue/PR | Status |
|---|---|---|
| — | — | ⬜ |

## A3 — Extension-first

Decision rule per feature/sub-feature:

| Can it be… | Then |
|---|---|
| a language server (diagnostics, completion, code actions, hover, go-to) | build as LS (any language; Rust/TS/PHP) + thin Zed extension |
| a snippet / slash command / theme / grammar / MCP context server | Zed extension |
| needs a panel, custom view, gutter UI, title bar | fork |

Applied to the plan:

| Feature | Extension part | Fork part |
|---|---|---|
| 19 WordPress tools | `wp-hooks-ls` language server (go-to hook, find hook usages, completion of hook names) | Hooks panel |
| 20 file templates | — (needs "new file" flow) | fork |
| 21 inspections | PHPCS/WPCS via LS (existing or small wrapper) | Problems panel |
| 25 Laravel | routes/config/view go-to via LS | artisan panel |
| 26 postfix/live templates | snippets via extension | postfix needs completion hook → LS can provide postfix completions as code completions |
| 28 TODO | LS emitting TODO as hint diagnostics | panel optional |
| Themes (14) | Zenith themes as extension | — |

Benefit: extension/LS parts also work in **stock Zed** and other editors.

## Effort

Ongoing; ~1–2 days per upstream PR attempt.
