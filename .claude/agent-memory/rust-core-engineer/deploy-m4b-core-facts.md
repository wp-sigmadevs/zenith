---
name: deploy-m4b-core-facts
description: zenith_deploy M4b core (on_save.rs, upload_mapped) - verified APIs, design constraints from panel.rs exhaustive matches, sabotage script
metadata:
  type: reference
---

Verified @ feat/plan37-m4b-core 290c4fe4ba, 2026-11-26.

- `workspace::SaveIntent` (pane.rs:84) is reachable from zenith_deploy (already depends on `workspace`). `util::paths::{PathMatcher, PathStyle}`; `PathMatcher::new_lenient(globs, PathStyle::local(), on_error)`, `is_match_std_path(&Path)` (sources match by starts_with/ends_with of whole parts; globset `*` crosses `/`).
- panel.rs matches `UploadOutcome` and `ServerStoreEvent` exhaustively: adding a variant needs a panel.rs edit. M4b core therefore reports a Fixed exclusion as `UploadOutcome::Blocked("... never uploaded automatically ...")`; C3 may add a real variant.
- `AsyncApp::background_spawn` needs `gpui::AppContext as _` imported. `smol::lock::Semaphore::acquire_arc(&Arc<Self>)` gives a guard held for the task's life.
- Mapped project files live in `ServerStore.mapped`, never `copies` (clear_cache removes files of closed copies when any copy of the server is open: only a test with a gated running upload shows the bug). `copy_ref`/`copy_mut` span both maps for settle/run_upload.
- Sabotage runner: scratchpad `sabotage.py <file> <filter> 'name|||regex|||repl'...` (regex count=1, restores file in finally). Quote `&` carefully in repl (`\&` stays literal and breaks compile). macOS `sed -i` needs `-i ''`: use perl -pi -e.
- Python-appended test code is not formatted by the hook: run `rustfmt --edition 2024 <file>` before committing (it only touched the appended block).
