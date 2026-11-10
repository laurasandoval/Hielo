# Hielo agent guide

Hielo is an iOS 26+ Swift package with a small public SwiftUI API and
an internal UIKit runtime. Keep the public product free of third-party
dependencies.

The package uses three private UIKit mechanisms—remote keyboard-window lookup,
input host-view lookup, and keyboard view snapshotting—lightly obfuscated. Use
at your own risk. Handle missing symbols gracefully; symbol presence does not guarantee runtime safety.

## Invariants

1. One host owns at most one presentation.
2. Keep the original input focused while presenting over its frozen snapshot.
3. Every UIKit mutation must have an idempotent cleanup path.
4. Cancellation must leave the app and keyboard interactive.
5. Do not add app-specific layout or focus policy to the package.
6. Mount popover content once per presentation; do not measure a hidden duplicate.
7. Every session teardown must restore the source and presentation binding;
   callbacks from an old host must not affect a new presentation.

## Release scope

The public API on main is the Hielo popover modifier family, `.hieloHost()`, and
the keyboard-height utility `onHieloKeyboardHeightChange` with
`HieloKeyboardHeight`. Session/source types are internal. Keyboard pinning, restoration, and explicit
session control are preserved on `laurasandoval--keyboard-pinning`; do not
reintroduce them to main without an explicit scope change.

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

- `Sources/Hielo/Session`: public host modifier and internal session; `Internal` holds overlay mechanics
- `Sources/Hielo/Hosting`: app- and keyboard-window presentation hosts
- `Sources/Hielo/Popover`: public modifiers and styles; `Internal` holds UI, placement, and motion
- `Sources/Hielo/Keyboard`: public keyboard-height utility; public API only (`keyboardLayoutGuide`) and must never depend on `Runtime` or other private UIKit
- `Sources/Hielo/Runtime`: private UIKit discovery and capture boundary
- `Tests/HieloTests`: tests grouped to mirror source features
- `Examples/HieloDemo`: the iOS demonstration app
- `Documentation`: architecture and physical-device verification

Use one Swift type per file. Prefer SwiftUI in the example app; UIKit is
expected only inside the package's keyboard-window boundary and the public
`keyboardLayoutGuide` reader in `Sources/Hielo/Keyboard`.

Keep popover placement, drag behavior, and motion tuning independent. The
source's UIKit window resolution and SwiftUI screen measurement are both
required for correct cross-window placement on physical devices.

## Verification

Use verification appropriate to the changed behavior and report precisely what
was checked. Follow `Documentation/Testing.md` on a physical iPhone before
release; a successful build alone does not validate private keyboard runtime
behavior. Respect the contributor’s local instructions for test and device use.

## Contributions

- Prefer branch names `{github-username}--{custom-branch-name}`, all lowercase.
- Use lowercase, subject-only commit messages.
- Before copying this package into a consumer repository for a bespoke need,
  consider a pull request here when the functionality could benefit consumers
  worldwide. Keep genuinely app-specific behavior in the consumer.
