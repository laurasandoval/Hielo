# Testing Hielo

Run automated tests on an iOS 26 Simulator, then validate every release on a
physical iPhone.

## Overlay

- With no text field focused, open both the leading and trailing menus.
- Confirm bottom controls resolve to bottom-leading and bottom-trailing so each
  menu grows into the available screen space.
- Move a source to the top half of a test screen and confirm a centered vertical
  anchor resolves to the equivalent top corner.
- Confirm no keyboard focus is required and outside taps still dismiss.
- Present content taller than the safe area; confirm it shifts to the top safe
  area edge while preserving its natural height.
- Present content wider than the screen; confirm it shifts to the leading safe
  area edge without resizing and lets the consumer's view overflow naturally.
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

## Content lifetime and cancellation

- Supply a custom environment value and an environment object above the source;
  confirm content receives both when opened.
- Confirm content `onAppear`/`task` runs only for the presented tree, and local
  state resets on reopening. Bind model state if it must survive dismissal.
- Begin with empty content that later loads; confirm outside taps still dismiss
  while waiting and the menu expands when a finite size becomes available.
- Set the presentation binding to `false` during opening and while expanded;
  confirm the source returns and reopening works.
- With a menu open, tap Back: confirm only the menu dismisses. Tap Back again
  and confirm navigation proceeds. Repeat with and without keyboard focus.
- Navigate programmatically during opening or collapse; confirm no menu or
  shield remains.
- Change content size while expanded and confirm placement and outside taps
  follow its new frame.

## Additional conditions

- Predictive text enabled and disabled
- Different keyboard types and heights
- Dictation and globe controls
- Third-party keyboard selected
- Background and foreground during each active state
- Rotation and multitasking where the consuming app supports them

Missing keyboard runtime support should fall back to the app-window presentation.
A missing source/host should reset the binding without leaving an interaction shield.
Existing private symbols may still have incompatible implementations on a new OS;
the symbol checks alone cannot rule out a runtime crash.

## Experimental submenus

- Open Camera, Photos, and Files with and without keyboard focus.
- Confirm expansion to the window minus 8 points per side, bottom placement,
  concentric corners, and coordinated content scaling and fading.
- Collapse with Back, then dismiss and reopen; verify content state resets.
- Confirm drag dismissal is disabled in the expanded state and outside taps
  still dismiss, including taps on navigation controls.
- Repeat with a custom popover animation, no animation, and Reduce Motion.
