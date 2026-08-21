import UIKit

@MainActor
protocol KeyboardFreezeRuntimeProviding {
  func capture() -> KeyboardFreezeRuntime.Capture?
  func keyboardWindows(on screen: UIScreen) -> [UIWindow]
  func pauseSnapshot(_ snapshotView: UIView)
}
