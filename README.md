# KeyboardFreeze

Freeze the visible iOS system keyboard, place custom SwiftUI content over it,
or pin it inside a moving page.

KeyboardFreeze is designed for interactions such as attachment menus that open
without dismissing the keyboard and sidebars that carry the keyboard with the
page while they move.

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

## Present content over a frozen keyboard

Create one session for the screen and install its host modifier on the full
page:

```swift
import KeyboardFreeze
import SwiftUI

struct ChatView: View {
  @State private var keyboardFreeze = KeyboardFreeze()
  @State private var source = KeyboardFreezeSource()
  @FocusState private var inputIsFocused: Bool

  var body: some View {
    VStack {
      Spacer()

      Button("Open attachments", systemImage: "plus", action: openAttachments)
        .keyboardFreezeSource(source)

      TextField("Message", text: .constant(""))
        .focused($inputIsFocused)
    }
    .keyboardFreeze(keyboardFreeze)
  }

  private func openAttachments() {
    keyboardFreeze.presentOverlay(from: source) { _ in
      Text("Hello from above the keyboard")
        .padding()
    }
  }
}
```

The real text input stays focused. Taps outside the custom content dismiss it
by default, or can be handled with `onOutsideTap`.

## Pin the keyboard into a moving page

Capture and pin the keyboard when page movement begins:

```swift
keyboardFreeze.pinKeyboard {
  inputIsFocused = false
}
```

After the page returns to the input, restore the real keyboard without its
usual entrance animation:

```swift
keyboardFreeze.restoreKeyboard {
  inputIsFocused = true
}
```

Apply `.keyboardFreeze(keyboardFreeze)` to the entire moving page. The pinned
snapshot is hosted by that modifier, so it follows the page's transforms.

## Failure handling

Presentation methods return `KeyboardFreezeActivationResult`. A missing or
changed private runtime returns `.keyboardUnavailable` and leaves the live
keyboard alone.

Use one `KeyboardFreeze` instance per screen or flow. Call `cancel()` when a
manually managed session is no longer needed; the default host lifecycle
cancels automatically when its view disappears.

## Example app

Open `Examples/KeyboardFreezeDemo/KeyboardFreezeDemo.xcodeproj` to run the
overlay and moving-sidebar examples. Keyboard snapshot behavior must also be
verified on a physical iPhone because Simulator keyboard windows can differ.

## License

KeyboardFreeze is available under the MIT License.
