---
name: gpui-deploy-c4-facts
description: zenith_deploy C4 upload-on-save checkbox - confirmation_holds store invariant, window.prompt in a dialog, test traps (fork feat/deploy-c4 0ac6a6b4cd)
metadata:
  type: reference
---

- `on_save::confirmation_holds(old, new, reconfirmed_fp)` is the one rule for `upload_on_save_confirmed`: true only if reconfirmed fingerprint == fingerprint(new), or old already true and fingerprint unchanged. Store `save` assigns it on every server; dialog uses it to draw the checkbox (checked = `upload_on_save && holds`). The old store code (`!confirmed_now && needs_reconfirm`) let a false->true flag with unchanged fingerprint through.
- `window.prompt(PromptLevel::Warning, msg, Some(detail), &[PromptButton::cancel("Cancel"), PromptButton::new("Turn on")], cx)`; answer index 1 = accept. Spawn with `cx.spawn(async move |this, cx| this.update(cx, ..))`, keep the Task in a field, guard double prompts with a bool. Re-check the settings fingerprint on accept (prompt names the state at open).
- Tests: one `workspace()` per `#[gpui::test]` (a second one panics "same activation priority" for RemoteHostPanel): split matrix cases into separate tests. Reopen a closed dialog with the existing `reopen(&workspace, cx)`, not `window.root`.
- Keystroke walk to the Mappings-tab checkbox: focus `add_mapping_focus`, `tab` (checkbox is next in document order). Server-list buttons: focus `add_server_focus`, `tab enter` = Remove.
- Sabotage script pattern: backup `.rs.bak` copies in scratchpad, python replace asserting count==1, `trap restore EXIT`; nextest filter needs `test(a) | test(b)`.
- Not covered: a hand-edited servers.json with the flag already true is trusted at LOAD (no persisted integrity token); only the save path is enforced.
