# Hielo

This development branch preserves keyboard pinning and explicit session control.
The first release on `main` exposes only the popover API. See
[Keyboard pinning](Documentation/KeyboardPinning.md) for the retained API.

Present morphing Liquid Glass popovers anywhere, including over a frozen iOS
system keyboard.

Hielo is designed for interactions such as glass menus that open
over the keyboard without dismissing it.

> Hielo uses three private UIKit mechanisms—remote keyboard-window
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
page. Apply `hieloPopover` to any source view and size the expanded content
with normal SwiftUI layout modifiers:

```swift
import Hielo
import SwiftUI

struct ChatView: View {
  @State private var session = HieloSession()
  @State private var isMenuPresented = false
  @FocusState private var inputIsFocused: Bool

  var body: some View {
    VStack {
      Spacer()

      Button("Open menu", systemImage: "plus") {
        isMenuPresented = true
      }
        .frame(width: 48, height: 48)
        .hieloPopover(
          isPresented: $isMenuPresented,
          attachmentAnchor: .leading
        ) {
          Text("Hello World")
            .frame(width: 250, height: 250)
        }

      TextField("Message", text: .constant(""))
        .focused($inputIsFocused)
    }
    .hieloHost(session)
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
.hieloPopover(
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
.hieloPopover(
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

When expanded content would cross an edge, the popover translates into the
available safe area without changing its natural size. Content larger than the
safe area pins to its leading or top edge. Hielo never resizes the
consumer's view to prevent overflow.

Popover content mounts once per presentation, so its local state resets when
reopened. Keep persistent state in the parent or a model. The source's environment
is copied when the popover opens; later ancestor environment changes are not
forwarded automatically. Use bindings or observable models for changing data,
and set `isPresented` to `false` to dismiss.

For fully custom presentations, `presentOverlay` and `HieloSource`
remain available as lower-level APIs. Supply environment dependencies explicitly
when creating content through these imperative methods.

## Failure handling

Low-level keyboard-presentation methods return `HieloActivationResult`.
When required keyboard resources cannot be resolved, activation returns
`.keyboardUnavailable` and leaves the live keyboard alone. These checks are
best-effort: an incompatible private implementation can still fail at runtime. `hieloPopover` falls back to the app window when a
keyboard capture is unavailable and fails closed only when it cannot resolve
its source or host.

Use one `HieloSession` instance per screen or flow. Call `cancel()` when a
manually managed session is no longer needed; the default host lifecycle
cancels automatically when its view disappears.

## Example app

Open `Examples/HieloDemo/HieloDemo.xcodeproj` to run the
minimal morphing glass-menu example. Keyboard snapshot behavior must also be
verified on a physical iPhone because Simulator keyboard windows can differ.

## License

Hielo is available under the MIT License.

### Reading the demo code

The app in `Examples/HieloDemo` consumes the local package in
`Sources/Hielo`; demo helpers are not part of the package.

- `App/DemoAppView.swift`: navigation between the two demos.
- `Demos/Messages/MessagesDemoView.swift`: minimal integration with a separate glass button.
- `Demos/ChatGPT/ChatGPTDemoView.swift`: integration with an inline plain button.
- Each demo owns its menu, presentation state, and keyboard focus.
- `Helpers`: shared composer layout and button styling. Menu types stay in their demo.

Paths above are relative to `Examples/HieloDemo/HieloDemo`.

### Managed sessions and popover styles

For ordinary popovers, apply `.hieloHost()` to the containing page. It
owns the session and cancels presentations when the page disappears. Keep
`.hieloHost(session)` when you need explicit pinning or restoration.

Popovers default to a glass source. Apply `.hieloPopoverStyle(.plain)`
after `.hieloPopover(...)` for an inline button without its own glass.
The presented popover still uses glass. A style can also be inherited from
an ancestor. Passing `sourceGlass` explicitly overrides the inherited style.

### Animation

Use `.hieloPopoverAnimation(.spring(duration: 0.4, bounce: 0.2))` after the
popover modifier or on an ancestor to customize opening, dismissal, and drag
snap-back. The default is `.spring(duration: 0.3, bounce: 0.2)`. Pass `nil` to
disable animation. The choice is captured at presentation time; Reduce Motion
also disables transitions. Supply a finite animation so dismissal can complete.
