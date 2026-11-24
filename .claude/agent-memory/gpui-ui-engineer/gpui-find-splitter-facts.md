---
name: gpui-find-splitter-facts
description: Find in Files preview splitter (plan 44 #18) - state location, drag pattern, test traps (zenith_search, fork 61641aaa63 on feat/plan44-find-splitter)
metadata:
  type: project
---

- Splitter height lives in `PopupSizes.find_preview` (popup.rs), read via `popup::preview_height(cx)`; Frame min body for Find grows by (preview - 210) so the list keeps >= 3 rows (min body raised 440 -> 445: 440 gave only 2.9 rows).
- `on_drag_move` listeners are capture-phase and not hit-tested: attach on the handle itself. Seed drag from mouse-down (y, height, max) and compute absolute height, not deltas (clamp drift).
- Real drag test: `simulate_mouse_down/move/up` on `debug_bounds("zenith-find-splitter")`; off-window drags via `FindInFilesModal::split_between` (cfg(test)).
- Double-click in tests: `VisualTestContext::simulate_event(MouseDownEvent{click_count:2,..})` + MouseUpEvent; `simulate_click` always sends click_count 1.
- Max-clamp test must assert the exact preview height (room - 78), not only list >= 78: the raised min body hides the difference.
- `rustfmt --check` on zenith_search.rs has a pre-existing diff at ~1894 (keymap path); never format the whole file.
