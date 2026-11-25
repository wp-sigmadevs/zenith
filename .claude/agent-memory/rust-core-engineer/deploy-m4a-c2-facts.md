---
name: deploy-m4a-c2-facts
description: zenith_deploy M4a C2 - buffer-bytes APIs, sabotage-run tactics under heavy load, hook traps
metadata:
  type: reference
---

Verified @ feat/plan37-m4a-edit-remote bd66251ea0, 2026-11-25.

- Buffer text as saved: `buffer.rope_for_version(buffer.saved_version()).to_string()` (Deref to TextBuffer), then `.replace('\n', buffer.line_ending().as_str())`; `buffer.encoding().name()=="UTF-8"`, `buffer.has_bom()` (EF BB BF prefix). Mirrors worktree.rs:1870 write_file. Test: `Buffer::local("x", cx)` + `buffer.did_save(buffer.version(), None, cx)` marks it saved.
- `gpui::TaskExt as _` must be imported for `Task<Result<()>>::detach_and_log_err(cx)`. Tests need `gpui::AppContext as _` for `cx.new`.
- `WeakEntity::read_with(cx,..)`/`update(cx,..)` return Result; `AsyncApp::update` returns R. Dropping the last strong Entity<Buffer> in a gpui test frees it immediately (Weak::upgrade None).
- Supercharger hook blocks `git checkout -- <path>` in Bash (use stash, or restore from in-memory originals in a script). The cargo-fmt PostToolUse hook reformats files after Write, so exact-text sabotage patterns must be taken from `git show HEAD:file`.
- Machine load ~170 with other sessions: one nextest rebuild can wait 10+ min on the cargo lock. Batch sabotages (disjoint tests) into groups, one build per group.

C2 review round (fork 563272bd24):
- Test buffers with a real file path: `test_support::init(cx, servers, &remote, cache_dir)` gives AppState + the global ServerStore; `app_state.fs.as_fake().insert_tree(parent, json!({..}))` (insert_file needs an existing parent dir), `Project::test(fs, [parent], cx)`, `project.open_local_buffer(path, cx)`; abs path = `buffer.file()?.as_local()?.abs_path(cx)` (language::LocalFile). A second Project over the same FakeFs gives a second Buffer of the same file (simulates two windows).
- NEVER put backticks in an unquoted shell heredoc (`<<EOF`): the shell runs them (it ran `stat`). Use <<'EOF' and pass paths via python.
- Sabotage patterns must tolerate rustfmt: allow optional trailing comma and newline whitespace; run groups of disjoint sabotages per build.
- sha2/hex are workspace deps but not in zenith_deploy's: cache-path hash is FNV-1a 64 (std only).
