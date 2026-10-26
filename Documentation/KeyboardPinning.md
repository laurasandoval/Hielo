# Keyboard pinning

This API is preserved on `laurasandoval--keyboard-pinning`; it is not included in
the first popover-only Hielo release on main. No new declarative pinning API is
introduced here.

```swift
import Hielo
import SwiftUI

// Stored on the consuming view:
@State private var session = HieloSession()
@FocusState private var inputIsFocused: Bool

// Attach to the page that will move with its keyboard snapshot:
.hieloHost(session)

// Capture and mount before resigning focus:
session.pinKeyboard(resigningFirstResponder: {
  inputIsFocused = false
})

// Restore the real keyboard after a cancelled dismissal:
session.restoreKeyboard(focusingFirstResponder: {
  inputIsFocused = true
})

// Or discard the snapshot without restoring focus:
session.unpinKeyboard()
```

These snippets show the integration points rather than a complete view. Consumers
supply their own drag/navigation behavior. `pinKeyboard` returns
`HieloActivationResult`; handle unavailable keyboard capture before committing to
an interaction. The session also retains custom overlay presentation, lifecycle
configuration, cancellation, and status inspection.

The renamed implementation and its existing tests were compiled. Runtime pinning
and restoration still require physical-device verification.
