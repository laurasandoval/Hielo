import UIKit

@MainActor
final class KeyboardFreezeOverlayWindow: UIWindow {
  override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
    super.hitTest(point, with: event) ?? rootViewController?.view
  }
}
