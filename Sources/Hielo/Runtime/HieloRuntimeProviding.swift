import UIKit

@MainActor
protocol HieloRuntimeProviding {
  func capture() -> HieloRuntime.Capture?
  func keyboardWindows(on screen: UIScreen) -> [UIWindow]
  func pauseSnapshot(_ snapshotView: UIView)
}
