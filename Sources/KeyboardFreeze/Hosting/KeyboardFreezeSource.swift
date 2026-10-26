import Observation
import UIKit

/// Tracks a SwiftUI view that overlay content can animate from or position around.
@MainActor
@Observable
/// A source view’s location for positioning a keyboard overlay.
///
/// Create a source and attach it to a view with
/// ``View/keyboardFreezeSource(_:)`` before presenting an overlay from it.
public final class KeyboardFreezeSource {
  struct WindowResolution {
    let frameInScreen: CGRect
    let safeAreaFrameInScreen: CGRect
    let window: UIWindow
  }

  /// The tracked view’s frame in screen coordinates, or `nil` when unavailable.
  public private(set) var frameInScreen: CGRect?

  @ObservationIgnored var onDetach: (@MainActor () -> Void)?

  @ObservationIgnored private var screen: UIScreen?
  @ObservationIgnored private weak var owner: UIView?

  /// Creates a source that has not yet been attached to a view.
  public init() {}

  func resolveFrame(on expectedScreen: UIScreen) -> CGRect? {
    guard screen === expectedScreen else { return nil }
    return frameInScreen
  }

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

  func update(frameInScreen: CGRect, screen: UIScreen, owner: UIView) {
    guard !frameInScreen.isEmpty else { return }
    self.owner = owner
    self.screen = screen
    self.frameInScreen = frameInScreen
  }

  func clear(owner: UIView) {
    guard self.owner === owner else { return }
    self.owner = nil
    screen = nil
    frameInScreen = nil
    let action = onDetach
    onDetach = nil
    action?()
  }
}
