import UIKit

@MainActor
final class HieloPin {
  let snapshotView: UIView
  let keyboardWindow: UIWindow
  let keyboardFrameInScreen: CGRect

  init(capture: HieloRuntime.Capture) {
    snapshotView = capture.snapshotView
    keyboardWindow = capture.keyboardWindow
    keyboardFrameInScreen = capture.keyboardFrameInScreen
  }
}
