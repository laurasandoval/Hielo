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
that snapshot and the SwiftUI overlay content above it. A presentation-owned interaction
shield blocks the source app window, including navigation controls, while the
presentation is active. It consumes outside taps without activating underlying
controls. The page-level SwiftUI shield remains a fallback for low-level callers
whose source app window cannot be resolved.

When no keyboard capture is available, `KeyboardPopover` inserts the same
presentation view into its source app window without a snapshot. Centered
attachment-axis components resolve toward the nearest screen edge, so the
popover grows toward the side with more available space. Explicit attachment
components remain unchanged.

The input remains focused, so the app retains its cursor and keyboard-driven
layout.

`KeyboardPopover` measures its source in SwiftUI screen coordinates; the UIKit
source resolver identifies the app window. These measurements are intentionally
separate because keyboard and app windows can use different coordinate spaces.
The session converts source geometry into the host window's coordinates.

Expanded content mounts only inside the presentation host. Its intrinsic SwiftUI
size updates the host frame and starts expansion; there is no hidden second
content tree in the source page. The initial host uses the source frame so
outside taps remain available even while content is empty or loading. Placement
aligns matching `UnitPoint` anchors. One normalized expansion value drives surface size,
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

## Ownership and lifetime

| Owner | Responsibility |
| --- | --- |
| `KeyboardFreeze` | Owns one active presentation and its cleanup. Public entry points live in `Session/KeyboardFreeze.swift`; overlay and restoration mechanics live in `Session/Internal`. |
| `KeyboardFreezeOverlayPresentation` | Owns the UIKit host, snapshot, outside-tap recognizer, and one-shot teardown notification. |
| `KeyboardPopover` | Owns the binding, source measurement, and active presentation ID. |
| `KeyboardPopoverOverlay` | Owns content measurement, expansion, drag, and dismissal animation. |

The popover lifecycle is request → mount/measure → expand → collapse → teardown.
A session cancellation or source disappearance can go directly to teardown from
any phase. The source reader also requests teardown when UIKit detaches it from
its window, covering navigation removal independently of SwiftUI disappearance.
The session clears its ownership before notifying the source, which
restores the source view and clears the presentation binding. IDs keep callbacks
from a removed host from dismissing a later presentation. Normal collapse removes
the host and restores the source in the same nonanimated transaction to avoid
displaying two glass surfaces during handoff.

`keyboardPopover` copies the source's SwiftUI environment into the separate
hosting root at presentation time. This is a snapshot, not a live bridge for
later ancestor environment changes. Bindings and observable reference models
remain the way to supply changing data. The low-level imperative `presentOverlay`
API has no originating SwiftUI environment; its caller must supply dependencies
on the content it returns. Presentation-scoped actions such as SwiftUI `dismiss`
are not rebound to this custom host; dismiss through `isPresented` or the session.

Content-local state lasts for one presentation and resets when reopened. Put
state that must survive dismissal in the consuming view or model. Consumer
content must have a finite natural size; constrain flexible containers such as
scroll views using ordinary SwiftUI layout.

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

Private runtime checks are best-effort compatibility guards. A missing class or
selector can be handled, but its presence cannot prove that a future OS preserves
the private implementation's contract. Physical-device checks remain necessary.
