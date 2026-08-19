import UIKit

@MainActor
final class KeyboardFreezePin {
  let snapshotView: UIView
  let keyboardWindow: UIWindow
  let keyboardFrameInScreen: CGRect

  init(capture: KeyboardFreezeRuntime.Capture) {
    snapshotView = capture.snapshotView
    keyboardWindow = capture.keyboardWindow
    keyboardFrameInScreen = capture.keyboardFrameInScreen
  }
}
