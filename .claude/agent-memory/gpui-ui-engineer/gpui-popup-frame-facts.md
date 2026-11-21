---
name: gpui-popup-frame-facts
description: zenith_search shared popup Frame (drag + resize grip), embedded Picker width root cause, test traps (fork 69cc7fe185 on feat/modal-resize)
metadata:
  type: project
---

- Embedded `Picker` menu has a fixed `.w(shape width)` (34rem default); inside a wider card it leaves a dead strip. Fix hook: `Picker::set_embedded_size(width, Option<height>, cx)` (picker.rs, render.rs) - width overrides, a height makes results fill (like preview pickers). Card border is 2px total (`popup::BORDER`): pass `card - 2px` or the picker overflows.
- `zenith_search/src/popup.rs` `Frame` owns offset/drag/resize/body-bounds for SE and FIF; sizes live in a `PopupSizes` global keyed by `PopupKind` (session persistence). Height stored = body under header, measured by a `canvas` into `Rc<Cell<Bounds>>`.
- Drag state must seed `last` from `MouseDownEvent.position`; seeding on first `on_drag_move` loses the first deltas (tests simulating 4 moves saw half the delta).
- Simulated pointer positions outside the window dismiss/lose the modal (debug_bounds -> None): test clamping by calling `frame.resize_to` directly with off-window points, not via `simulate_mouse_move`.
- Probe bounds with `cx.debug_bounds(selector)` (needs `&mut VisualTestContext`); test window is 1920x1080, rem 14px.
- `cursor_nwse_resize()` exists in gpui_macros styles; grip icon via `Icon::from_path("icons/zenith_resize_grip.svg")` avoids touching `IconName`.
- FIF already measured full width pre-fix (hits/footer == header); only SE/Recent had the strip.
