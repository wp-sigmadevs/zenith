---
name: gpui-deploy-dialog-tabs-facts
description: zenith_deploy C3 dialog tabs facts - ToggleButtonGroup lacks tab roles, editor a11y wrapper, native folder prompt vs modal replacement, focus-order test, glob validation (fork 1340bb4941 + feat/deploy-c3)
metadata:
  type: reference
---

- `ToggleButtonGroup` (ui/button/toggle_button.rs) builds `ButtonLike`s itself: only `tab_index(&mut isize)`, no role/`aria_selected` per button. `Button::toggle_state` gives `aria_toggled`, not selected. For `Role::Tab` + `aria_selected` build a focusable div: `.id().role(Role::Tab).aria_selected(b).tab_index(i).on_click()` (Enter/Space activate it via gpui keyboard click, div.rs ~3141); strip = `.role(Role::TabList).tab_group()`, panel = `.role(Role::TabPanel)`.
- Fork editors expose no a11y node: wrap in `div().id().role(TextInput|MultilineTextInput).aria_label().aria_value(text).track_focus(&editor.focus_handle(cx))` (pattern of settings_ui input_field.rs:232).
- `Workspace::prompt_for_open_path` falls back to an in-app modal when `use_system_path_prompts` is off: `ModalLayer::toggle_modal` hides the open dialog. From inside a modal use `cx.prompt_for_paths(PathPromptOptions{..})` (native) and test with `cx.simulate_path_prompt_response(|options| Some(vec![..]))` (works on VisualTestContext).
- `PathMatcher::new([pat], PathStyle::local())` errors on an invalid glob; `new_lenient` silently skips it (util/src/paths.rs ~830).
- Tab order test: editors are not tab stops; click each tab (`cx.simulate_click(debug_bounds(id).center(), Modifiers::none())`) to capture its focus handle, then `window.focus_next(cx)` and compare handles.
- Existing test helpers in dialog.rs tests: `text_of`, `types_into`, `reopen`, `error_text`; do not redefine.
- Multi-line editor setup: copy edit_prediction_ui rate modal feedback editor (disable scrollbars/minimap, SoftWrap::EditorWidth, hide gutter/line numbers/etc.).
