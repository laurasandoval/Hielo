# Testing Hielo

Run automated tests on an iOS 26 Simulator, then validate every release on a
physical iPhone.

## Overlay

- With no text field focused, open the menu from sources at the leading and
  trailing edges.
- Confirm bottom controls resolve to bottom-leading and bottom-trailing so each
  menu grows into the available screen space.
- Move a source to the top half of a test screen and confirm a centered vertical
  anchor resolves to the equivalent top corner.
- Confirm no keyboard focus is required and outside taps still dismiss.
- Present content taller than the safe area; confirm it shifts to the top safe
  area edge while preserving its natural height.
- Present content wider than the screen; confirm it shifts to the leading safe
  area edge without resizing and lets the consumer's view overflow naturally.
- Focus the text field and reopen the menus.
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

## Keyboard height and Photos sheet

Use the demo's Messages screen on a physical iPhone.

- Log or display `HieloKeyboardHeight` and confirm `current` and `lastVisible`
  update when the keyboard shows and hides, and that `lastVisible` persists
  after hiding.
- Dismiss the keyboard interactively and confirm `current` follows it.
- Repeat with different keyboards and heights: predictive text on and off,
  emoji, and a third-party keyboard.
- Rotate and confirm the value updates for the new window size.
- Open the Photos sheet and confirm its detent top lines up with where the
  keyboard's top edge was, with no gap or overlap.
- Confirm the composer stays above the sheet at the keyboard's position.
- Return from the sheet to the keyboard and confirm the composer does not jump.
- Attach a hardware keyboard and confirm `current` reports the shortcuts bar
  overlap, or `0` when there is none; confirm the sheet still gets a usable
  height from `lastVisible` or a sensible fallback.
- With floating and split keyboards (iPad), confirm `current` is `0`.
- In the Messages menu, tap a row other than Photos; confirm the other rows
  fade out and back in while the menu stays open, and that tapping Photos
  dismisses the popover and presents the sheet.
- Record the Photos sheet opening, returning to the keyboard from the text
  field, and being swiped away; step through it and confirm the composer never
  moves except to settle down after a swipe.

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
- Drop focus programmatically while a popover is open over the keyboard;
  confirm the popover ends, the source returns, and no shield remains.
- Confirm `onDismiss` runs once per dismissal, after the source is restored.

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
