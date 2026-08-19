import ObjectiveC
import UIKit

@testable import KeyboardFreeze

@MainActor
final class FakeKeyboardFreezeRuntime: KeyboardFreezeRuntimeProviding {
  var captureResult: KeyboardFreezeRuntime.Capture?
  var discoveredWindows: [UIWindow] = []
  private(set) var pausedSnapshots: [UIView] = []

  func capture() -> KeyboardFreezeRuntime.Capture? {
    captureResult
  }

  func keyboardWindows(on screen: UIScreen) -> [UIWindow] {
    discoveredWindows.filter { $0.screen === screen }
  }

  func pauseSnapshot(_ snapshotView: UIView) {
    pausedSnapshots.append(snapshotView)
  }

  static func populated(
    keyboardHeight: CGFloat = 300
  ) -> FakeKeyboardFreezeRuntime {
    let runtime = FakeKeyboardFreezeRuntime()
    let keyboardWindow = makeWindow()
    let screenBounds = keyboardWindow.screen.bounds
    keyboardWindow.frame = screenBounds
    let keyboardHostView = UIView(
      frame: CGRect(
        x: 0,
        y: screenBounds.height - keyboardHeight,
        width: screenBounds.width,
        height: keyboardHeight
      )
    )
    keyboardWindow.addSubview(keyboardHostView)
    runtime.captureResult = KeyboardFreezeRuntime.Capture(
      keyboardWindow: keyboardWindow,
      keyboardHostView: keyboardHostView,
      snapshotView: UIView(frame: keyboardHostView.bounds)
    )
    return runtime
  }

  private static func makeWindow() -> UIWindow {
    let selector = NSSelectorFromString("new")
    guard let method = class_getClassMethod(UIWindow.self, selector) else {
      fatalError("UIWindow must inherit NSObject.new")
    }
    typealias WindowFactory =
      @convention(c) (
        AnyClass,
        Selector
      ) -> Unmanaged<AnyObject>
    let factory = unsafeBitCast(
      method_getImplementation(method),
      to: WindowFactory.self
    )
    guard
      let window = factory(UIWindow.self, selector).takeRetainedValue()
        as? UIWindow
    else {
      fatalError("NSObject.new returned an unexpected window type")
    }
    return window
  }
}
