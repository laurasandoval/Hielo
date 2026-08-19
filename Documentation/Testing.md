# Testing KeyboardFreeze

Run automated tests on an iOS 26 Simulator, then validate every release on a
physical iPhone.

## Overlay

- Focus the message field and open the attachment panel.
- Confirm the cursor remains focused and blinking.
- Tap inside the custom panel.
- Tap app content and several places on the frozen keyboard.
- Dismiss and reopen repeatedly.
- Repeat with the emoji keyboard, including during scroll momentum.

## Moving sidebar

- Begin dragging the page while the keyboard is visible.
- Confirm the frozen keyboard is flush with the physical screen bottom.
- Settle with the sidebar open, then return to chat.
- Confirm the real keyboard does not visibly slide into place.
- Reverse direction while restoration is active.
- Repeat rapid direction changes.

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
