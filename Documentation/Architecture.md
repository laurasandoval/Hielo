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

When a keyboard is visible, the runtime captures and pauses its snapshot. A
full-window presentation view is inserted into the system keyboard window with
that snapshot and the SwiftUI overlay content above it. A matching interaction
shield blocks the app window while the presentation is active.

When no keyboard capture is available, `KeyboardPopover` inserts the same
presentation view into its source app window without a snapshot. Centered
attachment-axis components resolve toward the nearest screen edge, so the
popover grows toward the side with more available space. Explicit attachment
components remain unchanged.

The input remains focused, so the app retains its cursor and keyboard-driven
layout.

`KeyboardPopover` builds on this boundary. Its source view measures itself and
the expanded content with ordinary SwiftUI layout, then aligns matching
`UnitPoint` anchors. One normalized expansion value drives surface size,
continuous per-corner interpolation, source blur and opacity, and the expanded
content's center-based visual scale. Both content layers remain centered in the
changing surface. The expanded content keeps its final layout throughout the
transition and is clipped by the changing glass surface.

The app-side source uses an identity glass transition. The custom overlay
finishes its collapse before the source is restored, so a surrounding
`GlassEffectContainer` cannot match the returning source against a sibling
glass element.

Popover dragging is rubber-banded in every direction. A non-dismissed release
animates back to its anchor; dismissal is intentionally limited to a downward
release.

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
