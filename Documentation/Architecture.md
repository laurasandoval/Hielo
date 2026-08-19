# Architecture

KeyboardFreeze owns one `@MainActor` session per consuming screen or flow. Its
public `Status` is an observable summary of an internal ownership state machine:

```text
idle
├── overlay
└── pinned ── restoring ── idle
                 └── repinning ── pinned
```

## Overlay presentation

The runtime captures and pauses the visible keyboard snapshot. A full-window
presentation view is then inserted into the system keyboard window with the
snapshot and a SwiftUI hosting controller. A matching SwiftUI interaction
shield blocks the app window while the presentation is active.

The input remains focused, so the app retains its cursor and keyboard-driven
layout.

## Pinned presentation

The snapshot is mounted by the root `.keyboardFreeze(_:)` modifier before the
consumer's focus closure runs. The live keyboard resigns focus with UIKit
animations suppressed for the smallest possible interval. Because the snapshot
belongs to the modified page, it follows the page's offset and transforms.

## Restoration

The frozen snapshot stays visible while focus returns. A display link hides all
keyboard windows, including replacements created during restoration. On the
matching keyboard-did-show notification, window alpha is restored and the
snapshot is removed in one frame.

If restoration is interrupted, the session moves through `repinning`, dismisses
the live keyboard again, and retains the original snapshot. A newer focus
request is queued until repinning completes.

## Runtime boundary

`KeyboardFreezeRuntimeProviding` isolates keyboard discovery, private symbol
lookup, snapshot creation, and timeline pausing. Tests inject a fake runtime and
never call private UIKit APIs.
