---
name: gpui-php-status-facts
description: zenith_php_tools status popover/modal facts - PopoverMenu on a status item, handle.show lease trap, Tab/SelectNext, debug_selector text rows (fork f641559fc5 on feat/plan44-php-status)
metadata:
  type: project
---

- `PopoverMenu::new(id).with_handle(h).anchor(Anchor::BottomRight).on_open(Rc<..>).menu(|w,cx| Some(cx.new(..))).trigger_with_tooltip(Button, tooltip)` replaces `.on_click` of the trigger; builder runs on every open (popover_menu.rs show_menu). `handle.show/toggle` calls `on_open` synchronously: never call it inside `status.update` if `on_open` updates the same entity (double lease) - read the handle out first.
- Base keymap binds context-less Tab to `menu::SelectNext` (default-macos.json:15); a view with no SelectNext handler gets a dead Tab. Handle SelectNext/SelectPrevious -> `window.focus_next/prev` (tab_index on buttons). Escape is context-less `menu::Cancel`: no keymap edit needed.
- A status row test without reading the entity: `.debug_selector(move || format!("zenith-php-row {label} = {text}"))` + `cx.debug_bounds(..)`.
- Tests: `VisualTestContext::debug_bounds` needs `&mut`, so a `wait_for(cx, || cx.debug_bounds(..))` closure cannot borrow cx: use a `wait_for_window(cx, |cx| ..)` helper. Fake `PATH`/managed dirs must be disabled in tests (TEST_CANDIDATES set => no path_dirs, no managed) or the dev machine's tools leak in.
- `Path::strip_prefix("")` succeeds for any path: guard an empty HOME before `~/`.
