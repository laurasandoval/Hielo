import Observation
import UIKit

/// Tracks a SwiftUI view that overlay content can animate from or position around.
@MainActor
@Observable
public final class KeyboardFreezeSource {
  struct WindowResolution {
    let frameInScreen: CGRect
    let safeAreaFrameInScreen: CGRect
    let window: UIWindow
  }

  public private(set) var frameInScreen: CGRect?

  @ObservationIgnored private var screen: UIScreen?
  @ObservationIgnored private weak var owner: UIView?

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
  }
}
