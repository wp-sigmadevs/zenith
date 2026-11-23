# 42 — PHPantom from `main`: WordPress stubs and external library roots

> **Status (2026-11-22):** 🟨 approved (owner 2026-11-22). M0 done: `main` @ `b759b41da6` built + installed (`docs/guides/fork-findings.md`). M1 config writer in fork `zenith` (`cce1a4825b`, `d58e761135`; stubs write dropped). Merged in `zenith` via `integrate/batch-b` (not built into an app) the writer uses a Zenith-only `XDG_CONFIG_HOME` (`4c4cf69555`). Binary SHA-256 is recorded in docs only, not checked in code. Originally PROPOSED; follows plan 41 (M2 stubs, a no-op).

## Problem
Two owner-visible bugs, one cause: PHPantom 0.11.1 (the latest release, the one Zed's PHP extension downloads) has no way to learn about code outside the project.
1. WordPress functions (`register_activation_hook`, `wp_die`, `plugin_dir_path`) show `Function 'x' not found`, even in a project with `vendor/php-stubs/wordpress-stubs`.
2. A folder added with "Add Library Path…" (for example `~/WPProjects/wordpress`) is never indexed.

Evidence (read from docs.rs 0.11.1 and `strings` on the installed binary, by two agents):
- 0.11.1 reads only `root_uri` in `initialize`; it ignores `workspaceFolders` and does not implement `workspace/didChangeWorkspaceFolders`.
- Its config schema has no `stubs` and no `indexing.include`. `indexing` has only `strategy`, `exclude`, `extensions`.
- `lsp.phpantom.initialization_options.stubs` (our plan 41 M2 write, commit `878e868254`) is silently ignored.

## What `main` has
Checked on 2026-11-22 via the GitHub API: `main` HEAD `b759b41da61efc31c66e823245cc0118ef5f87bb` (2026-11-20), MIT licence. Its `config-schema.json` has:
- `stubs.paths`: array of strings; stub files or directories (relative to the workspace root unless absolute) whose declarations win over any other declaration of the same name.
- `indexing.include`: array of strings; files or directories indexed even though the workspace scan skips them, relative to the workspace root unless absolute; missing entries are ignored. Whether paths outside the workspace are treated as library code is UNVERIFIED (description truncated in my read); M0 checks it.

No release contains either key (latest release 0.11.1, 2026-10-07; none since).

## Options
- **(a) Wait for a release.** Zero risk, unknown date. The two bugs stay.
- **(b) Build `main` at a pinned commit and run it (recommended).** Fixes both bugs now. Cost: Zenith carries a pre-release language server until a release ships.
- **(c) Symlink stubs into each project.** Writes app-made files into user repos and is unverified (does the scanner follow links outside the workspace?). Rejected.
- **(d) Patch the fork of PHPantom ourselves.** Not ours to maintain. Rejected.

## Plan (option b)
**M0 build and verify (lead, about half a day).**
1. In a new empty scratch directory, clone `PHPantom-dev/phpantom_lsp` and check out one commit (start with `b759b41da6`). Read the commits since 0.11.1 that touch `main.rs`, `backend/`, network, process spawning and `build.rs` (security review, below).
2. `cargo build --release` with its own target directory (not the fork's).
3. Run `phpantom_lsp --version` and `--help`, nothing else. No tests.
4. Install to `~/.local/share/zenith/tools/phpantom/<short-sha>/phpantom_lsp` and a symlink `current` pointing at it. Record the SHA and the SHA-256 of the binary in `docs/guides/fork-findings.md`.
5. Confirm from the real run in the app (owner): hover on `register_activation_hook` shows the WordPress signature, and the added library path resolves.

**M1 app wiring (rust-core-engineer, `zenith_php_tools`, zero upstream edits).**
- Delete `wire_phpantom_stubs`, `add_phpantom_stubs` and their two call sites (the dead 0.11.1 write); delete `wordpress_stubs_dir` if unused afterwards.
- New idempotent, background-thread function, run at startup and on worktree refresh, writing only when content changes. It maintains `~/.config/phpantom_lsp/.phpantom.toml` (`$XDG_CONFIG_HOME` honoured; macOS uses XDG, not Application Support): adds, never overwrites or reorders user content, leaves the file untouched and logs when it cannot parse it.
  - `[indexing] include`: every root in `zenith.external_libraries.paths`.
  - `[stubs] paths`: `<project>/vendor/php-stubs/wordpress-stubs` for WordPress projects when it exists. Not gated on the PHP-tools consent popup (the popup is skipped when a project already has tools, which is why plan 41 M2 never ran).
- When `~/.local/share/zenith/tools/phpantom/current/phpantom_lsp` exists and the user has not set `lsp.phpantom.binary.path`, the app sets it through `update_settings_file`. A user-set path is never overridden.

**M2 docs (docs-editor).** Plan 41: mark M2 "no mechanism on 0.11.1; superseded by plan 42". Plan 41 risks: replace "unpinned download" with the pinned build. Add the build commands and the SHA to `docs/guides/fork-findings.md`. Plan README row.

**M3 exit.** When PHPantom ships a release containing both keys: drop the source build, delete `binary.path`, let the extension's download take over, keep M1's config writer.

Upstream touches: 0 lines. No new crate dependency expected (`toml_edit` only if already in `Cargo.lock`).

## Security review (before M1 ships)
- The binary is built from third-party source and runs as the language server on every PHP project, with the user's file access. Mitigations: pinned commit, MIT licence, read the diff since 0.11.1 for network calls, process spawning (PHPantom already runs phpstan/phpcs/mago when configured), and file writes; record the SHA-256; no auto-update; build happens by the owner or lead, never silently by the app.
- The app writes `~/.config/phpantom_lsp/.phpantom.toml` and one settings key. Both are user-visible, idempotent and additive.
- Reviewer: security-engineer on the diff since 0.11.1 and on the writer.

## Risks
- Pre-release server: regressions or crashes. Rollback: delete the `current` symlink and the `binary.path` key; the extension's 0.11.1 takes over.
- `indexing.include` may index all of WordPress core on every project that lists it: memory and startup cost (UNVERIFIED; PHPantom's benchmark is 578 MB on 33k files).
- A library root added by one project applies globally (the config file is global). Stale roots stay until removed. Fix: M1 writes only roots currently configured, and removes only entries it added (marker comment).
- `main` moves; re-pin deliberately, never track it.

## Open items
- UNKNOWN: are paths outside the workspace in `indexing.include` treated as library code (no diagnostics, lower priority)? M0.
- UNKNOWN: does the PHP extension honour `lsp.phpantom.binary.path`? Standard Zed setting; M0 confirms.
- UNKNOWN: memory and startup cost with WordPress core included.
- M0 (2026-11-22, work machine): security review 0.11.1..`b759b41` found no new network, process-spawn or file-write sites. Stdio test: `add_action` resolved into WordPress `wp-includes/plugin.php:441`. Not yet confirmed in the app (step 5).
