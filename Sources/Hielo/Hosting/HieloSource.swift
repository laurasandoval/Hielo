import Observation
import UIKit

/// Tracks a SwiftUI view that overlay content can animate from or position around.
///
/// Attach a source to a view with `hieloSource(_:)` before presenting an overlay from it.
@MainActor
@Observable
final class HieloSource {
  struct WindowResolution {
    let frameInScreen: CGRect
    let safeAreaFrameInScreen: CGRect
    let window: UIWindow
  }

  /// The tracked view’s frame in screen coordinates, or `nil` when unavailable.
  private(set) var frameInScreen: CGRect?

  @ObservationIgnored var onDetach: (@MainActor () -> Void)?

  @ObservationIgnored private weak var owner: UIView?

  /// Creates a source that has not yet been attached to a view.
  init() {}

  func resolveWindow() -> WindowResolution? {
    guard let frameInScreen, let window = owner?.window else { return nil }
    let safeAreaFrameInScreen = window.convert(
      window.bounds.inset(by: window.safeAreaInsets),
      to: nil
    )
    return WindowResolution(
      frameInScreen: frameInScreen,
      safeAreaFrameInScreen: safeAreaFrameInScreen,
      window: window
    )
  }

  func update(frameInScreen: CGRect, owner: UIView) {
    guard !frameInScreen.isEmpty else { return }
    self.owner = owner
    self.frameInScreen = frameInScreen
  }

  func clear(owner: UIView) {
    guard self.owner === owner else { return }
    self.owner = nil
    frameInScreen = nil
    let action = onDetach
    onDetach = nil
    action?()
  }
}
