---
name: deploy-m4b-core-facts
description: zenith_deploy M4b core (on_save.rs, upload_mapped) - verified APIs, design constraints from panel.rs exhaustive matches, sabotage script
metadata:
  type: reference
---

Verified @ feat/plan37-m4b-core 290c4fe4ba, 2026-11-26.

- `workspace::SaveIntent` (pane.rs:84) is reachable from zenith_deploy (already depends on `workspace`). `util::paths::{PathMatcher, PathStyle}`; `PathMatcher::new_lenient(globs, PathStyle::local(), on_error)`, `is_match_std_path(&Path)` (sources match by starts_with/ends_with of whole parts; globset `*` crosses `/`).
- panel.rs matches `UploadOutcome` and `ServerStoreEvent` exhaustively: adding a variant needs a panel.rs edit. `UploadOutcome::Excluded(String)` now exists (`remote_edit.rs` ~218, emitted ~950 for a Fixed exclusion, "never uploaded automatically"); panel.rs:1016 handles it with `Blocked`.
- `AsyncApp::background_spawn` needs `gpui::AppContext as _` imported. `smol::lock::Semaphore::acquire_arc(&Arc<Self>)` gives a guard held for the task's life.
- Mapped project files live in `ServerStore.mapped`, never `copies` (clear_cache removes files of closed copies when any copy of the server is open: only a test with a gated running upload shows the bug). `copy_ref`/`copy_mut` span both maps for settle/run_upload.
- Sabotage runner: scratchpad `sabotage.py <file> <filter> 'name|||regex|||repl'...` (regex count=1, restores file in finally). Quote `&` carefully in repl (`\&` stays literal and breaks compile). macOS `sed -i` needs `-i ''`: use perl -pi -e.
- Python-appended test code is not formatted by the hook: run `rustfmt --edition 2024 <file>` before committing (it only touched the appended block).
- Skip/reconfirm answers are bound to `on_save::fingerprint` (target + anonymous + root + mappings); `RemoteStore::current_fingerprint(server_id)` returns it. A panel "always" answer must pass `current_fingerprint`, not the target (`set_skip_no_baseline_prompt(&id, &fingerprint, true)`).
