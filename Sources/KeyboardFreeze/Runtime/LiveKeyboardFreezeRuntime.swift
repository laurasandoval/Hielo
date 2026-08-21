import UIKit

@MainActor
struct LiveKeyboardFreezeRuntime: KeyboardFreezeRuntimeProviding {
  func capture() -> KeyboardFreezeRuntime.Capture? {
    KeyboardFreezeRuntime.capture()
  }

  func keyboardWindows(on screen: UIScreen) -> [UIWindow] {
    KeyboardFreezeRuntime.keyboardWindows(on: screen)
  }

  func pauseSnapshot(_ snapshotView: UIView) {
    KeyboardFreezeRuntime.pauseSnapshot(snapshotView)
  }
}
