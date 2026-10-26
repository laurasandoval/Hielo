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

## API and maintainability

- Follow SwiftUI and UIKit conventions: native types, bindings, environment-based
  modifiers, semantic controls, and familiar naming before custom abstractions.
- Provide useful defaults so the common case needs little configuration. Expose
  focused customization using Apple types such as `Animation`, rather than a
  parallel configuration language.
- Hide runtime complexity from consumers while keeping internal ownership,
  coordinate spaces, state transitions, and cleanup explicit for maintainers.
- Keep shared behavior in one implementation; isolate real style differences.
  Prefer small, concrete components over speculative protocols or wrappers.
- Document public APIs with concise summaries, parameter/default semantics,
  examples, and relevant limitations. Keep demo integration visible at call sites.
- Preserve private-runtime fail-closed behavior. Do not expand private API use
  merely to simplify a public call site.

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

Use verification appropriate to the changed behavior and report precisely what
was checked. Follow `Documentation/Testing.md` on a physical iPhone before
release; a successful build alone does not validate private keyboard runtime
behavior. Respect the contributor’s local instructions for test and device use.
