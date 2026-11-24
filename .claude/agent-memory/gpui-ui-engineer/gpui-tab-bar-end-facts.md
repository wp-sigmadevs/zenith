---
name: gpui-tab-bar-end-facts
description: Verified facts for putting toolbar items at the tab-bar end (zenith_rails tab_bar_end, plan 44 #3/#6, fork dd9df1aa31)
metadata:
  type: reference
---

- `Pane::set_render_tab_bar_buttons` closure returns (left, right); stock plus/split/zoom come from `default_render_tab_bar_buttons` (made `pub`, pane.rs:4325) and only draw while the pane is focused. Terminal panel and debugger set their own closures; they are not in `workspace.panes()` / `Event::PaneAdded` so a hook installed there never touches them.
- Registry keyed by the pane's toolbar entity id (`cx: &mut Context<Toolbar>` inside `pane.toolbar().update`) avoids touching a leased Pane; `cx.on_release` cleans up, but dropped entities release only when an `update` FINISHES (test: `cx.update(|_, _| ())` before asserting).
- A toolbar item returning `Hidden` still gets `set_active_pane_item`; an all-hidden toolbar draws no row. Entity rendered as a child view in the tab bar re-renders with the pane; register-after-first-draw needs `cx.notify()`.
- `zed` cannot name `zenith_rails` (optional feature): go through `zenith::tab_bar_end` wrapper.
- Test traps: an empty pane draws NO tab bar (add a `workspace::item::test::TestItem`); `debug_bounds` needs a fresh `window.draw(cx).clear(cx)`; action handlers must `window.defer` before `workspace.update` (lease panic).
- QuickActionBar `show` is the quick_actions setting; under rails it is forced false (toolbar hidden) so render gates on the setting itself.
- Round 2: toolbar-id registry entries carry a visibility predicate (Fn(&Pane,&App)); draws_tab_bar_end = RailsActive && TabBarSettings show && show_tab_bar_buttons; zed tests: crate::zed::tests::init_test + RailsActive global set before window gives QuickActionBar location test (no rails::init needed).
