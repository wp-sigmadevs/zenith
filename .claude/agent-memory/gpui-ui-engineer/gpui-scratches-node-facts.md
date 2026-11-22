---
name: gpui-scratches-node-facts
description: Verified fork facts for the project-panel "Scratches and Consoles" node (invisible worktree owner, glue rows, menu/test traps); fork a8c0a64c65 branch feat/scratches-node
metadata:
  type: reference
---

Verified @ worktree `~/GithubProjects/zed-scratches` (feat/scratches-node, from zenith 66bdccbd97).

- Project panel `update_visible_entries` iterates `project.visible_worktrees` only (project_panel.rs:4687); an invisible worktree needs a glue-appended `VisibleEntriesForWorktree` and a seeded `state.expanded_dir_ids.entry(wt).or_insert(vec![root.id])` (zenith_section needs that entry). `zenith_libraries()` runs after every rebuild (hook :4956); the old body early-returns without libraries, so scratches rows are appended by a separate call after it.
- Invisible worktree: held weakly by WorktreeStore unless `retain_worktrees` (worktree_store.rs:1037) so the owner keeps an `Entity<Worktree>`; no git (worktree.rs:1375 `track_git_repositories = self.visible`, :527 root repo discovery visible only); `find_or_create_worktree` returns a VISIBLE worktree if one contains the path, so check `!is_visible()` before holding.
- `Entity<Project>.update(cx: &mut AsyncApp, ..)` returns the closure value directly (a `Task`), not a Result; `Task` has no `.log_err()`.
- File finder candidates = `WorktreeStore::visible_worktrees_and_single_files` (file_finder.rs:1274), a method on the store, not Project. `FileFinder.picker` is private: cross-crate tests can only assert the candidate set.
- `ContextMenu.items` is private (no accessor): test menus via a pure `items()` fn + `menu.select_first(&SelectFirst,..)`, `menu.confirm(&Confirm,..)` and a global `cx.on_action` counter (dispatch bubbles to root; `run_until_parked`).
- Keyboard rename of a worktree ROOT row is allowed by `rename_impl` (project_panel.rs:2638); trash/delete exclude roots (`disjoint_effective_entries_excluding_roots`). So F2 on the "Scratches" root row would rename the store folder; menu hides it, keyboard does not (no guard without a project_panel.rs hook).
- `#[cfg_attr(not(feature = ..), path = "zenith_libraries/x_off.rs")] mod x;` inside non-mod-rs `zenith_libraries.rs` works (path relative to the file's directory).
- `rustfmt <parent.rs>` also reformats child mods (banner.rs): `git checkout` the unrelated file afterwards.
- ProjectPanel does not rebuild on SettingsStore changes outside its own settings; a node-setting flip shows once the worktree is dropped/added (WorktreeRemoved/Added events) or the next update.
- Settings content added `project_panel_node` only in settings_content/zenith.rs (default via `unwrap_or(true)`); assets/settings/default.json NOT edited (upstream-file budget).
- Shared CARGO_TARGET_DIR trap hit again: bogus "no field project_panel_node" -> `touch crates/settings_content/src/*.rs`.
- Sabotage driver pattern: python, backups in scratchpad, atexit restore, regex `test \S*NAME \.\.\. FAILED`; rustfmt reflows sabotage anchor strings (anchor on the formatted text).
