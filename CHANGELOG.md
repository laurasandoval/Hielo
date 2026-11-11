# Changelog

All notable changes to Hielo will be documented here.

## Unreleased

## 0.1.0

- Morphing Liquid Glass popovers with `.hieloHost()`, `.hieloPopover`,
  `.hieloPopoverStyle`, and `.hieloPopoverAnimation`, with custom source and
  destination shapes, and an optional `onDismiss` action.
- Popovers present over the frozen system keyboard while the input stays
  focused, using private UIKit. Missing runtime support falls back to the app
  window.
- Adaptive app-window presentation when no keyboard is visible.
- `onHieloKeyboardHeightChange` and `HieloKeyboardHeight`: a public-API-only
  keyboard-height utility built on `keyboardLayoutGuide`, reporting `current`
  and `lastVisible` heights.
- Messages demo app with a glass-menu popover over the keyboard and a Photos
  sheet sized to the keyboard's height.
- State-machine, placement, drag behavior, shape, and runtime tests.
