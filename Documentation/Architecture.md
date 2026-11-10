# Architecture

Each `.hieloHost()` owns an internal `@MainActor` session. The session manages
one popover presentation at a time: `idle → overlay → idle`. Consumers use
bindings and modifiers; the session and source resolver are implementation details.

Keyboard pinning and restoration are preserved on
`laurasandoval--keyboard-pinning`, outside the first release's API and runtime.

## Overlay presentation

When a keyboard is visible, the runtime captures and pauses its snapshot. A
full-window presentation view is inserted into the system keyboard window with
that snapshot and the SwiftUI overlay content above it. A presentation-owned interaction
shield blocks the source app window, including navigation controls, while the
presentation is active. It consumes outside taps without activating underlying
controls. The page-level SwiftUI shield remains a fallback when the source app window
cannot be resolved.

When no keyboard capture is available, `HieloPopover` inserts the same
presentation view into its source app window without a snapshot. Centered
attachment-axis components resolve toward the nearest screen edge, so the
popover grows toward the side with more available space. Explicit attachment
components remain unchanged.

The input remains focused, so the app retains its cursor and keyboard-driven
layout.

`HieloPopover` measures its source in SwiftUI screen coordinates; the UIKit
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
| `HieloSession` | Owns one active presentation and its cleanup. The session is internal; overlay mechanics live in `Session/Internal`. |
| `HieloOverlayPresentation` | Owns the UIKit host, snapshot, outside-tap recognizer, and one-shot teardown notification. |
| `HieloPopover` | Owns the binding, source measurement, and active presentation ID. |
| `HieloPopoverOverlay` | Owns content measurement, expansion, drag, and dismissal animation. |

The popover lifecycle is request → mount/measure → expand → collapse → teardown.
A session cancellation or source disappearance can go directly to teardown from
any phase. The source reader also requests teardown when UIKit detaches it from
its window, covering navigation removal independently of SwiftUI disappearance.
The session clears its ownership before notifying the source, which
restores the source view and clears the presentation binding. IDs keep callbacks
from a removed host from dismissing a later presentation. Normal collapse removes
the host and restores the source in the same nonanimated transaction to avoid
displaying two glass surfaces during handoff.

A keyboard-hosted presentation also tears down when the keyboard is dismissed
(`keyboardDidHideNotification`). The keyboard window stops rendering once its
keyboard is gone, so a collapse animation running there may never report
completion; without this path the source would stay hidden. `onDismiss` runs
after teardown, once the source is restored.

`hieloPopover` copies the source's SwiftUI environment into the separate
hosting root at presentation time. This is a snapshot, not a live bridge for
later ancestor environment changes. Bindings and observable reference models
remain the way to supply changing data. Presentation-scoped actions such as SwiftUI `dismiss`
are not rebound to this custom host; dismiss through `isPresented`.

Content-local state lasts for one presentation and resets when reopened. Put
state that must survive dismissal in the consuming view or model. Consumer
content must have a finite natural size; constrain flexible containers such as
scroll views using ordinary SwiftUI layout.

## Keyboard height

`onHieloKeyboardHeightChange` lives in `Sources/Hielo/Keyboard` and is
independent of the private keyboard runtime: it uses only public API and must
not depend on `HieloRuntimeProviding` or the presentation host.

The modifier adds a background `HieloKeyboardHeightReader`, whose UIKit view
owns the measurement. Once in a window, it constrains a zero-width probe view
to the vertical anchors of its own `keyboardLayoutGuide`, measured in window coordinates, so a change in
the guide's height lays out the probe. In that layout pass the reader computes
the guide's overlap with the window's bottom edge. An overlap no taller than
the bottom safe-area inset counts as no keyboard (`current` is `0`); otherwise
the value also becomes `lastVisible`. The result is delivered on a later
main-actor turn, outside the layout pass, and only when it differs from the
last delivered value. Leaving the window deactivates the constraints and cancels
pending delivery; reentry measures again. Each modifier keeps its own
`lastVisible`.

## Runtime boundary

`HieloRuntimeProviding` isolates keyboard discovery, private symbol
lookup, snapshot creation, and timeline pausing. Tests inject a fake runtime and
never call private UIKit APIs.

Private runtime checks are best-effort compatibility guards. A missing class or
selector can be handled, but its presence cannot prove that a future OS preserves
the private implementation's contract. Physical-device checks remain necessary.
