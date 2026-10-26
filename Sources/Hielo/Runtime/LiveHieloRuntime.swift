import UIKit

@MainActor
struct LiveHieloRuntime: HieloRuntimeProviding {
  func capture() -> HieloRuntime.Capture? {
    HieloRuntime.capture()
  }

  func keyboardWindows(on screen: UIScreen) -> [UIWindow] {
    HieloRuntime.keyboardWindows(on: screen)
  }

  func pauseSnapshot(_ snapshotView: UIView) {
    HieloRuntime.pauseSnapshot(snapshotView)
  }
}
