# KeyboardFreeze

Present morphing Liquid Glass popovers anywhere, including over a frozen iOS
system keyboard.

KeyboardFreeze is designed for interactions such as glass menus that open
over the keyboard without dismissing it.

> KeyboardFreeze uses three private UIKit mechanisms—remote keyboard-window
> lookup, input host-view lookup, and keyboard view snapshotting—lightly
> obfuscated. Use at your own risk.

## Requirements

- iOS 26 or later
- Swift 6.2 or later
- Xcode 26 or later

## Installation

In Xcode, choose **File → Add Package Dependencies** and enter:

```text
https://github.com/laurasandoval/KeyboardFreeze
```

## Present a keyboard popover

Create one session for the screen and install its host modifier on the full
page. Apply `keyboardPopover` to any source view and size the expanded content
with normal SwiftUI layout modifiers:

```swift
import KeyboardFreeze
import SwiftUI

struct ChatView: View {
  @State private var keyboardFreeze = KeyboardFreeze()
  @State private var isMenuPresented = false
  @FocusState private var inputIsFocused: Bool

  var body: some View {
    VStack {
      Spacer()

      Button("Open menu", systemImage: "plus") {
        isMenuPresented = true
      }
        .frame(width: 48, height: 48)
        .keyboardPopover(
          isPresented: $isMenuPresented,
          attachmentAnchor: .leading
        ) {
          Text("Hello World")
            .frame(width: 250, height: 250)
        }

      TextField("Message", text: .constant(""))
        .focused($inputIsFocused)
    }
    .keyboardFreeze(keyboardFreeze)
  }
}
```

The modifier supplies the Liquid Glass surface. Both the source and expanded
content can contain any SwiftUI view. Expanded content can hug its content or
set a fixed size with `frame`; no package-specific sizing style is required.
When the keyboard is visible, the popover freezes it and presents above its
snapshot. Without a keyboard, the same popover presents in the app window.

The default transition expands from a capsule into a continuously rounded
rectangle with a 32-point corner radius. Customize both ends with familiar
SwiftUI-style shapes:

```swift
.keyboardPopover(
  isPresented: $isMenuPresented,
  sourceShape: .rect(cornerRadius: 12),
  popoverShape: .rect(cornerRadius: 24)
) {
  SettingsView()
    .frame(width: 280, height: 320)
}
```

For a source that already owns its appearance, including a non-glass source,
pass `sourceGlass: nil`. The expanded popover remains Liquid Glass:

```swift
.keyboardPopover(
  isPresented: $isMenuPresented,
  sourceGlass: nil,
  sourceShape: .circle,
  popoverShape: .rect(cornerRadius: 28)
) {
  ProfileActions()
    .frame(width: 240, height: 280)
}
```

`.leading` means leading-center over a keyboard. In the app window, its centered
axis adapts to the source position, becoming top-leading or bottom-leading so
the popover expands into the available space. `.trailing`, `.top`, and `.bottom`
adapt the same way. Explicit corners such as `.bottomTrailing`, as well as
custom unit points, remain supported. The real text input stays focused when
one is active. Taps outside dismiss the popover, and the expanded surface can be
dragged in any direction. Only a downward release dismisses it.

For fully custom presentations, `presentOverlay` and `KeyboardFreezeSource`
remain available as lower-level APIs.

## Failure handling

Low-level keyboard-presentation methods return `KeyboardFreezeActivationResult`.
A missing or changed private runtime returns `.keyboardUnavailable` and leaves
the live keyboard alone. `keyboardPopover` falls back to the app window when a
keyboard capture is unavailable and fails closed only when it cannot resolve
its source or host.

Use one `KeyboardFreeze` instance per screen or flow. Call `cancel()` when a
manually managed session is no longer needed; the default host lifecycle
cancels automatically when its view disappears.

## Example app

Open `Examples/KeyboardFreezeDemo/KeyboardFreezeDemo.xcodeproj` to run the
minimal morphing glass-menu example. Keyboard snapshot behavior must also be
verified on a physical iPhone because Simulator keyboard windows can differ.

## License

KeyboardFreeze is available under the MIT License.
