import UIKit

@MainActor
struct LiveHieloRuntime: HieloRuntimeProviding {
  func capture() -> HieloRuntime.Capture? {
    HieloRuntime.capture()
  }

  func pauseSnapshot(_ snapshotView: UIView) {
    HieloRuntime.pauseSnapshot(snapshotView)
  }
}
