import UIKit

@MainActor
final class HieloPresentationView: UIView {
  private let onDismiss: @MainActor () -> Void

  init(onDismiss: @escaping @MainActor () -> Void) {
    self.onDismiss = onDismiss
    super.init(frame: .zero)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) is unavailable")
  }

  override func accessibilityPerformEscape() -> Bool {
    onDismiss()
    return true
  }
}
