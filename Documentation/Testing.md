# Testing KeyboardFreeze

Run automated tests on an iOS 26 Simulator, then validate every release on a
physical iPhone.

## Overlay

- With no text field focused, open both the leading and trailing menus.
- Confirm bottom controls resolve to bottom-leading and bottom-trailing so each
  menu grows into the available screen space.
- Move a source to the top half of a test screen and confirm a centered vertical
  anchor resolves to the equivalent top corner.
- Confirm no keyboard focus is required and outside taps still dismiss.
- Focus the text field and reopen both menus.
- Confirm the cursor remains focused and blinking.
- Confirm the menu is leading-aligned and vertically centered on its source.
- Confirm the source remains centered while it blurs and fades away.
- Confirm expanded content scales from its center without relayout or blur.
- Repeat with custom source and popover shapes; confirm all corners animate
  continuously and finish at the requested geometry.
- Repeat with `sourceGlass: nil`; confirm the resting source has no package-
  supplied glass and the expanded popover remains Liquid Glass.
- On dismissal, confirm the source glass appears in place without morphing from
  a neighboring glass element.
- Drag left, right, and up; confirm resistance keeps the menu near its anchor
  and release springs it back.
- Drag the menu down and confirm it morphs back into the source button.
- Tap inside the menu.
- Tap app content and several places on the frozen keyboard.
- Dismiss and reopen repeatedly.
- Repeat with the emoji keyboard, including during scroll momentum.

## Additional conditions

- Predictive text enabled and disabled
- Different keyboard types and heights
- Dictation and globe controls
- Third-party keyboard selected
- Background and foreground during each active state
- Rotation and multitasking where the consuming app supports them

Missing private runtime support should produce `.keyboardUnavailable`, never a
crash, transparent interaction shield, hidden keyboard window, or disabled
UIKit animation state.
