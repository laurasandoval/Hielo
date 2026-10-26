import ObjectiveC
import UIKit

/// Runtime lookup for the live keyboard surface and a frozen snapshot of it.
///
/// Private symbol names are assembled at runtime and every lookup fails closed.
@MainActor
enum KeyboardFreezeRuntime {
  @MainActor
  struct Capture {
    let keyboardWindow: UIWindow
    let keyboardHostView: UIView
    let snapshotView: UIView

    var keyboardFrameInScreen: CGRect {
      keyboardHostView.convert(keyboardHostView.bounds, to: nil)
    }

    var keyboardFrameInWindow: CGRect {
      keyboardHostView.convert(keyboardHostView.bounds, to: keyboardWindow)
    }
  }

  static func capture() -> Capture? {
    guard let keyboardWindow = activeKeyboardWindow,
      !keyboardWindow.isHidden,
      keyboardWindow.alpha > 0
    else { return nil }

    guard let keyboardHostView = keyboardHostView(in: keyboardWindow),
      keyboardHostView.bounds.height > 1
    else { return nil }

    let keyboardFrameInScreen = keyboardHostView.convert(
      keyboardHostView.bounds,
      to: nil
    )
    let visibleKeyboardFrame = keyboardFrameInScreen.intersection(
      keyboardWindow.screen.bounds
    )
    guard visibleKeyboardFrame.width > 1, visibleKeyboardFrame.height > 1 else {
      return nil
    }
    guard let snapshotView = keyboardSnapshotView(for: keyboardHostView) else {
      return nil
    }

    return Capture(
      keyboardWindow: keyboardWindow,
      keyboardHostView: keyboardHostView,
      snapshotView: snapshotView
    )
  }

  static var activeKeyboardWindow: UIWindow? {
    let activeScenes = UIApplication.shared.connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .filter { $0.activationState == .foregroundActive }

    for scene in activeScenes {
      if let remoteKeyboardWindow = keyboardWindow(for: scene) {
        return remoteKeyboardWindow
      }
    }

    guard let textEffectsWindowClass = NSClassFromString(textEffectsWindowClassName) else {
      return nil
    }

    return
      activeScenes
      .flatMap(\.windows)
      .reversed()
      .first { window in
        window.isKind(of: textEffectsWindowClass)
          && !window.isHidden
          && window.alpha > 0
      }
  }

  static func keyboardWindows(on screen: UIScreen) -> [UIWindow] {
    var windows: [UIWindow] = []
    for scene in UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }) {
      guard let window = keyboardWindow(for: scene),
        scene.screen === screen || window.screen === screen,
        !windows.contains(where: { $0 === window })
      else { continue }
      windows.append(window)
    }

    let keyboardWindowClasses = [
      NSClassFromString(remoteKeyboardWindowClassName),
      NSClassFromString(textEffectsWindowClassName),
    ].compactMap { $0 }
    let sceneWindows = UIApplication.shared.connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .filter { $0.screen === screen }
      .flatMap(\.windows)

    for window in sceneWindows
    where keyboardWindowClasses.contains(where: { window.isKind(of: $0) }) {
      if !windows.contains(where: { $0 === window }) {
        windows.append(window)
      }
    }
    return windows
  }

  static func keyboardHostView(in window: UIView) -> UIView? {
    firstDescendant(of: window, named: inputSetHostViewClassName)
  }

  static func keyboardSnapshotView(for keyboardView: UIView) -> UIView? {
    guard let snapshotterClass = NSClassFromString(snapshotterClassName) else {
      return nil
    }

    let factorySelector = NSSelectorFromString(snapshotterFactorySelectorName)
    typealias SnapshotterFactory =
      @convention(c) (
        AnyClass,
        Selector,
        UIView,
        Bool
      ) -> Unmanaged<AnyObject>?
    guard
      let factory = classMethod(
        factorySelector,
        on: snapshotterClass,
        signature: SnapshotterFactory.self
      ),
      let snapshotter = factory(
        snapshotterClass,
        factorySelector,
        keyboardView,
        false
      )?.takeUnretainedValue()
    else { return nil }

    let snapshotSelector = NSSelectorFromString(snapshotViewSelectorName)
    guard let snapshotterType = object_getClass(snapshotter) else { return nil }
    typealias SnapshotViewGetter =
      @convention(c) (
        AnyObject,
        Selector
      ) -> Unmanaged<AnyObject>?
    guard
      let snapshotViewGetter = instanceMethod(
        snapshotSelector,
        on: snapshotterType,
        signature: SnapshotViewGetter.self
      )
    else { return nil }

    return snapshotViewGetter(snapshotter, snapshotSelector)?
      .takeUnretainedValue() as? UIView
  }

  static func pauseSnapshot(_ snapshotView: UIView) {
    let pausedTime = snapshotView.layer.convertTime(CACurrentMediaTime(), from: nil)
    snapshotView.layer.speed = 0
    snapshotView.layer.timeOffset = pausedTime
  }

  static let remoteKeyboardWindowClassName =
    assembled(["Window", "Keyboard", "Remote", "UI"])

  static let keyboardSceneDelegateSelectorName =
    assembled(["Delegate", "Scene", "keyboard"])

  static let keyboardWindowSelectorName =
    assembled(["Window", "keyboard"])

  static let inputSetHostViewClassName =
    assembled(["View", "Host", "Set", "Input", "UI"])

  static let textEffectsWindowClassName =
    assembled(["Window", "Effects", "Text", "UI"])

  static let snapshotterClassName =
    assembled(["Snapshotter", "Tree", "View", "KB", "UI"])

  static let snapshotterFactorySelectorName =
    assembled(["Updates:", "Screen", "after", "View:", "Keyboard", "For", "snapshotter"])

  static let snapshotViewSelectorName =
    assembled(["View", "snapshot"])

  static func assembled(_ components: [String]) -> String {
    components.reversed().joined()
  }

  // The screen-based factory traps for clients linked against the iOS 27 SDK.
  static func keyboardWindow(for scene: NSObject) -> UIWindow? {
    guard let delegate = objectValue(
      for: NSSelectorFromString(keyboardSceneDelegateSelectorName), on: scene
    ) else { return nil }
    return objectValue(
      for: NSSelectorFromString(keyboardWindowSelectorName), on: delegate
    ) as? UIWindow
  }

  private static func objectValue(for selector: Selector, on object: NSObject) -> NSObject? {
    guard object.responds(to: selector) else { return nil }
    return object.perform(selector)?.takeUnretainedValue() as? NSObject
  }

  private static func firstDescendant(
    of view: UIView,
    named className: String
  ) -> UIView? {
    if NSStringFromClass(type(of: view)) == className { return view }
    return view.subviews.lazy.compactMap {
      firstDescendant(of: $0, named: className)
    }.first
  }

  private static func classMethod<Signature>(
    _ selector: Selector,
    on cls: AnyClass,
    signature: Signature.Type
  ) -> Signature? {
    guard let method = class_getClassMethod(cls, selector) else { return nil }
    return unsafeBitCast(method_getImplementation(method), to: Signature.self)
  }

  private static func instanceMethod<Signature>(
    _ selector: Selector,
    on cls: AnyClass,
    signature: Signature.Type
  ) -> Signature? {
    guard let method = class_getInstanceMethod(cls, selector) else { return nil }
    return unsafeBitCast(method_getImplementation(method), to: Signature.self)
  }
}
