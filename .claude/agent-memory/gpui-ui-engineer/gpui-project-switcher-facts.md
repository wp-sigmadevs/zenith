---
name: gpui-project-switcher-facts
description: zenith_title_bar project switcher facts - leased-workspace test trap, remote/test-support dev-dep, window enumeration, title_bar hook fmt trap, pgrep self-match (fork feat/plan44-switcher 9000263754)
metadata:
  type: project
---

- Popover builder runs outside any workspace update; a test that builds the body inside `workspace.update_in`/`toggle_modal` panics "cannot read Workspace while it is already being updated". Build the entity first (`cx.update(|window, cx| project_switcher(..))`), then `toggle_modal(.., |_, cx| TestModal(switcher, cx.subscribe(&switcher, forward DismissEvent)))` with a test-only `ModalView` newtype: gives real focus + `cx.dispatch_action(menu::SelectNext/Confirm)`.
- Dev-deps that enable `remote/test-support` (project/workspace test-support) need `recent_projects = { features = ["test-support"] }` too, else recent_projects fails with non-exhaustive `RemoteConnectionOptions::Mock`.
- `WindowHandle::root` is test-only; other windows: `handle.downcast::<MultiWorkspace>()` + `handle.read(cx)` (Err for the window mid-update). Current window: `window.root::<MultiWorkspace>()` (Option<Option<Entity>>). Activate: `MultiWorkspace::activate(ws, None, window, cx)` + `window.activate_window()`.
- `workspace::Open`, `git::Clone`, `zed_actions::OpenRemote/OpenRecent` dispatched via `window.defer(cx, |w,c| { focus.focus; w.dispatch_action })` after `cx.emit(DismissEvent)`; tests catch them with global `cx.on_action`.
- The post-write formatter hook rewraps `.when(a || b, |this| {..})` chains past 100 cols into a 20/14 diff: add a separate short `.when_some(zenith_title_bar::chevron(cx), |this, i| this.end_icon(i))` line instead (+1 line per site).
- `rustfmt <file>` follows `mod` and reformats siblings (run.rs got touched): use `--config skip_children=true`.
- `Window::defer` runs its closure INSIDE an update of that window: a nested `WindowHandle::update` on the same window fails silently (Err swallowed by `.log_err()`) and a test that only checks "nothing changed" still passes. Use `cx.defer(|cx| handle.update(..))` (as upstream recent_projects does) for window-level work, and make the test move away from the state it asserts.
- `Workspace::toggle_modal` already closes an open modal of the same type; a `register_action` handler runs inside the workspace update, so build things that read the workspace (`app_state`, project keys) in `window.defer` first and pass them in. `ModalView` on the popover body gives a keyboard path with zero title_bar.rs lines (the PopoverMenuHandle lives in title_bar.rs, so a handle-based toggle would cost upstream lines).
- `select_row` tests: arrows skip headers, so row N is reached by looping SelectNext until `selected_index == N`, not N presses.
- Keymap: `secondary-alt-shift-k` -> `zenith_title_bar::ToggleProjectSwitcher` is unbound in every base keymap (cmd-alt-p, ctrl-alt-p, alt-shift-o/ctrl-alt-shift-o/-y/-j are taken).
- Never wait with `until ! pgrep -f "cargo ..."`: the pattern matches the waiting shell itself and loops forever.
- Disk: clippy --all-targets with test-support on a cold shared target + a concurrent bundle dropped `df -g` from 47 to 16 GiB in ~1 h.
