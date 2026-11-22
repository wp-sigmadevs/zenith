# 04 — Scratch Files

> **Status (2026-11-22):** 🟨 new/list/rename/trash/reveal + ⌘⇧N in fork `zenith`. Run scratch (ctrl-r), `zenith.scratches.*` settings, group by language: `da0a6707c1`, in fork `zenith` (verified: `git -C ~/GithubProjects/zed log zenith -- crates/zenith_scratches`; `66bdccbd97` is the current `zenith` head). Project-panel "Scratches and Consoles" node: see plan 39 (branch `feat/scratches-node`).

## Goal

JetBrains-style scratches: global, project-independent files of any language, listed in a panel, runnable, persistent.

## Parity checklist

- [ ] New scratch: pick language → creates `scratch_N.<ext>` (must)
- [ ] Scratches panel listing all scratches, newest first (must)
- [ ] Available from any project window (must)
- [ ] Rename / delete / reveal in Finder (must)
- [ ] Run scratch (PHP, JS/TS, shell, `.http`, SQL→DB tool later) (must)
- [ ] Scratch uses current project's context optionally (e.g. PHP autoload) (later)
- [ ] Buffers (`Buffers` folder for unnamed) — skip, Zed untitled buffers cover it

## UX

- Action `zenith_scratches::NewScratch` (`cmd-shift-n`, matches JetBrains) → language picker (reuse language selector modal) → opens new file in center pane.
- Panel "Scratches" in left dock, icon + list grouped by language, context menu: Rename, Delete (to Trash), Reveal, Run.
- Run → spawns a Zed task in terminal using per-extension runner map.

## Reconciled 2026-11-19

Verified against fork @ b4130a774e.

- Directory: `paths::data_dir()/scratches` (`paths.rs:144`; macOS `~/Library/Application Support/Zenith`). Not `~/.local/share/zenith/`.
- Delete: `Fs::trash(path, RemoveOptions)` (`fs/src/fs.rs:129`). `trash_file` in this plan is wrong.
- `cmd-shift-n` collides with `jetbrains.json:86,138` (file_finder) and `default-macos.json:722` (`NewWindow`). `zenith.json` must bind the same contexts.
- Must work with no project open (global scratches).
- Recommend an own panel, not a project_panel node. Superseded 2026-11-22: the owner approved a project-panel node too (plan 39); the panel stays.
- Owner decision pending: may `cmd-shift-n` override Go to File / New Window?

## Architecture

- Storage dir: `paths::data_dir()/scratches` (setting override).
- Files opened via `workspace.open_abs_path` — they're real files, so LSP/highlighting work.
- Panel watches dir via `fs.watch`.
- Run uses `task::SpawnInTerminal` with command from runner map; `$ZED_FILE` substitution.
- Project context: if `zenith.scratches.use_project_cwd`, set task cwd to active worktree root (so `require 'vendor/autoload.php'` works).

## Data & settings

```json
"zenith": {
  "scratches": {
    "enabled": true,
    "directory": null,
    "runners": {
      "php": "php {file}",
      "js": "node {file}",
      "ts": "npx tsx {file}",
      "sh": "bash {file}",
      "http": "httpyac send {file} --all"
    },
    "use_project_cwd": true
  }
}
```

## Actions & keymap

`NewScratch` (cmd-shift-n), `ToggleScratchesPanel`, `RunScratch` (ctrl-r when scratch focused), `DeleteScratch`, `RenameScratch`.

## Milestones

1. Storage + `NewScratch` action + language picker.
2. Panel with list, open on click, fs watch.
3. Context menu ops (delete → Trash via `fs.trash_file` *verify*).
4. Run via tasks.
5. Settings + tests.

## Tests

- Unit: filename generation, runner resolution by ext.
- gpui test with `FakeFs`: create → appears in panel; delete → removed.

## Risks

- `cmd-shift-n` may collide with existing Zed binding (new window) — make configurable.
- Files outside any worktree: LSPs may refuse/limit features (Intelephense ok single-file; tsserver ok).

## Effort

~1 week.
