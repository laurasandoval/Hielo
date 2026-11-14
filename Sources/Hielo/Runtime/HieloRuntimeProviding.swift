import UIKit

@MainActor
protocol HieloRuntimeProviding {
  func capture() -> HieloRuntime.Capture?
  func pauseSnapshot(_ snapshotView: UIView)
}
