---
name: gpui-deploy-c5-facts
description: zenith_deploy C5 Autodetect + remote folder picker - one credential gate, validate_root, task-cancel tests, keystroke traps (fork feat/deploy-c5 from fefbdd520c)
metadata:
  type: reference
---

- `AsyncWindowContext::update(|window, cx| R) -> Result<R>` (gpui app/async_context.rs ~316): `cx.update(|_, cx| spawn_operation(cx, fut))?.await` inside an `anyhow` async block. `AsyncApp::update` returns R directly.
- Cancelling remote work = dropping the `Task` field. Test: put a `futures::channel::oneshot::Sender` in `FakeRemote.list_gates`' receiver; `hold.is_canceled()` after `run_until_parked` proves the background future was dropped. After dropping the test's dialog handle, ONE `run_until_parked` is not enough: do `run_until_parked(); cx.update(|_, _| {}); run_until_parked();` (entity release flushes on an update, cancellation runs on the pass after).
- Enter on a focused control: click does NOT focus a `pressed` button wrapper (tests then hit the dialog's Confirm = save). Reach buttons by keyboard: focus the Root path editor handle, `tab` = Browse, `tab tab` = Autodetect. Add `.debug_selector` on the `pressed` wrapper div, not on the Button.
- `validate_root` (remote_path.rs) is the one gate for server text that becomes a path (pwd, folder names joined to the current path); error text never repeats the path. Status text from the server goes through `panel::plain_text(.., MAX_STATUS_CHARS)` / `shown(.., 200)`.
- `connect_selected` (dialog.rs) is the only caller of `(store.connect)(` and `store.open_session(`; a source test counts both. It returns the server clone with `password: None` as the "target" to compare later (`credentials_target_changed`).
- Not covered / risk: a server that echoes the typed password inside an error message would show it (plain_text strips controls, not secrets).
- Sabotage runner pattern: python script in scratchpad, in-memory original restored in `finally`, plus a full `src` copy and `trap ... EXIT` as backup; filter with `-E 'test(a) | test(b)'`.
