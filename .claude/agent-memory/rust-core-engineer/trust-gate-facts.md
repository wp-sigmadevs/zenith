---
name: trust-gate-facts
description: Verified worktree-trust facts for fork tool-running code (zenith_php_tools::worktree_trusted), fork sha 737e34125c
metadata:
  type: reference
---

- `TrustedWorktreesStore::can_trust` (crates/project/src/trusted_worktrees.rs:423 @ 26ad93f0dd) trusts every invisible worktree and any single-file worktree once any directory worktree is trusted. Not enough to gate tools that run in the file's folder.
- Fix lives in `zenith_php_tools::worktree_trusted` (the one gate for inspections, phpcbf, git): single-file/invisible needs its folder inside a trusted visible directory worktree (branch `fix/single-file-tool-trust`, 737e34125c).
- Test recipe: `Project::find_or_create_worktree(file, visible, cx)` makes the outside worktree; hold the returned Entity (project keeps invisible worktrees weak, dropped = `can_trust` false). `WorktreeStore::create_worktree` makes a single-file worktree even inside an existing folder. Marker proof = `vendor/bin/phpcs` shell script that touches `<folder>/ran`.
- Untrusted inspections: `cargo test -p zenith_inspections --lib` ~1 min; filter names by test name, not topic (a "worktree" filter silently ran 1 test).
- fmt: tests.rs of zenith_inspections still has pre-existing fmt diffs (lines ~727-1005); format a copy and splice only new tail.
- (2184d90c27) Endless-file tests: `/dev/zero` symlink plus `mkfifo` (Command, `#[allow(clippy::disallowed_methods)]`). Sabotage only the bounded variants (drop `is_file`, widen `take`); an unbounded read of /dev/zero eats RAM. A FIFO opened without the `is_file` guard hangs: run under `timeout`, then `pkill -f <test-bin>`. `fs.is_file` follows symlinks; `Fs::metadata` of a /dev/zero symlink says len 0 and not dir. `project::*` re-exports `fs::*` (RealFs). Real phpcs without `--standard` climbs to a parent `phpcs.xml`; with it, it does not (verified on easy-demo-importer's phpcs).
- Pre-existing red: `zenith_welcome` `test_panels_dock_like_phpstorm` expects terminal dock bottom, default.json says right.
- zsh in Bash tool: no word splitting of `$F`; use arrays for `git commit -- "${F[@]}"`.
