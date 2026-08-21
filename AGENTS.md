# KeyboardFreeze agent guide

KeyboardFreeze is an iOS 26+ Swift package with a small public SwiftUI API and
an internal UIKit runtime. Keep the public product free of third-party
dependencies.

The package uses three private UIKit mechanisms—remote keyboard-window lookup,
input host-view lookup, and keyboard view snapshotting—lightly obfuscated. Use
at your own risk. Preserve the fail-closed behavior when any symbol is missing.

## Invariants

1. One session owns at most one presentation.
2. Overlay and pinned modes never run at the same time.
3. Mount a frozen snapshot before dismissing the live keyboard.
4. Keep the snapshot mounted until restoration has completed.
5. Restoration must continue discovering replacement keyboard windows.
6. Every UIKit mutation must have an idempotent cleanup path.
7. Timeouts and `cancel()` must leave the app and keyboard interactive.
8. Do not add app-specific layout or focus policy to the package.

## Project structure

- `Sources/KeyboardFreeze/Session`: public session API and state machine
- `Sources/KeyboardFreeze/Hosting`: app- and keyboard-window presentation hosts
- `Sources/KeyboardFreeze/Pinning`: pinned snapshot and restoration ownership
- `Sources/KeyboardFreeze/Popover`: morphing popover UI, placement, and motion
- `Sources/KeyboardFreeze/Runtime`: private UIKit discovery and capture boundary
- `Tests/KeyboardFreezeTests`: tests grouped to mirror source features
- `Examples/KeyboardFreezeDemo`: the iOS demonstration app
- `Documentation`: architecture and physical-device verification

Use one Swift type per file. Prefer SwiftUI in the example app; UIKit is
expected only inside the package's keyboard-window boundary.

Keep popover placement, drag behavior, and motion tuning independent. The
source's UIKit window resolution and SwiftUI screen measurement are both
required for correct cross-window placement on physical devices.

## Verification

Build and run the example app on an iOS 26 Simulator, run the package test
scheme, and follow `Documentation/Testing.md` on a physical iPhone before a
release. Simulator success alone is not sufficient evidence for the private
keyboard snapshot runtime.
