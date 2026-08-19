# KeyboardFreeze

Freeze the visible iOS system keyboard and place custom SwiftUI content over it.

KeyboardFreeze is designed for interactions such as popover menus that open
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

      Button("Open menu", systemImage: "plus", action: openMenu)
        .keyboardFreezeSource(source)

      TextField("Message", text: .constant(""))
        .focused($inputIsFocused)
    }
    .keyboardFreeze(keyboardFreeze)
  }

  private func openMenu() {
    keyboardFreeze.presentOverlay(from: source) { _ in
      Text("Hello World")
        .padding()
    }
  }
}
```

The real text input stays focused. Taps outside the custom content dismiss it
by default, or can be handled with `onOutsideTap`.

## Failure handling

Presentation methods return `KeyboardFreezeActivationResult`. A missing or
changed private runtime returns `.keyboardUnavailable` and leaves the live
keyboard alone.

Use one `KeyboardFreeze` instance per screen or flow. Call `cancel()` when a
manually managed session is no longer needed; the default host lifecycle
cancels automatically when its view disappears.

## Example app

Open `Examples/KeyboardFreezeDemo/KeyboardFreezeDemo.xcodeproj` to run the
minimal morphing-popover example. Keyboard snapshot behavior must also be
verified on a physical iPhone because Simulator keyboard windows can differ.

## License

KeyboardFreeze is available under the MIT License.
