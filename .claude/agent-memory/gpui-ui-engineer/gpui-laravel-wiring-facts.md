---
name: gpui-laravel-wiring-facts
description: Facts from wiring zenith_laravel (clone of the wordpress wiring) - merge conflicts on zenith settings, two-kind caps, sabotage harness, clippy/fmt/lock traps
metadata:
  type: reference
---

Verified @ fork d2d312898c (worktree ../zed-wire, branch feat/wire-tools).

- Merging `zenith` into feat/wire-tools conflicts in `crates/settings_content/src/zenith.rs` and `assets/settings/default.json` every time two tools each add a settings struct at the same spot (wordpress vs hover_card). Resolve: keep both fields, both structs, both json blocks.
- `./script/clippy -p X` runs `cargo clippy --release --all-targets --all-features -- --deny warnings`: it builds the tree in release (slow first time) and flags `redundant_clone` in tests. `cargo shear` missing is only a notice.
- `cargo fmt -p zenith_laravel` is fine on a crate you wrote yourself (the fmt hook only runs after Write, not after python/Edit edits, so run fmt before `--check`).
- FakeFs `insert_file` does NOT create parent dirs: `fs.create_dir(parent).await` first when the test adds `a/b/c.php` under a dir the tree lacked.
- `Label` has no `.p_2()`; wrap in `div().p_2()`.
- Cargo.lock: new crate deps add a hunk in the crate's own entry plus one line in `zenith`'s deps; split with `git diff -U3 Cargo.lock` + python filter + `git apply --cached --recount` to commit each with its own change.
- Two-kind caps (views / route files) in one batch worker: compute `room` per root per kind from the live index counts once per batch, decrement/increment as `(known, contains_file after)` flips. A cap enforced only on the listing is bypassed by events.
- A sabotage driver (python, try/finally + atexit + signal restore, backups in scratchpad, regex on `test X ... FAILED`) ran ~40 sabotages unattended; sabotaging a "does not read a device" test needs an unbounded `std::fs::read` of /dev/zero (OOM/hang): leave it unsabotaged and say so.
- Event-order trap: `project.update(remove_worktree)` delivers `WorktreeRemoved` synchronously, so assert `pending.is_empty()` BEFORE `run_until_parked`, else the worker's `next_batch` (which skips files outside live roots) hides a missing `pending.retain`.

Review-fix pass @ fork fb48044b0c:
- Index keyed by file (`HashMap<PathBuf, Vec<RouteDefinition>>`, `HashMap<PathBuf, ViewDefinition>`); `find_*`/completions/counts derived by scan. A name two files share is listed twice; panel selection key = (name, file, line), views line 0; row ids include file(+line).
- Line-cap test must use a valid route plus a long trailing `// pad` comment, else the field cap also catches it and the sabotage does not fail.
- `./script/clippy` flags `redundant_clone` in non-test code too (`dot_name.clone()` before last use).
- Splitting a commit whose test file mixes two findings: reverse the later finding on a temp copy, commit that blob (copy into tree, `git add`, commit, copy final back), re-verify tests on the temp state. A heredoc followed by a newline ends the `&&` chain: the next line runs unconditionally.
- `trap ... EXIT` restores at the end of each Bash call; do not expect a swapped file to persist across calls.
