import UIKit

/// An invisible view whose layout reports changes to the keyboard layout guide.
///
/// `HieloKeyboardHeightReader` constrains this view to the guide's vertical
/// anchors. UIKit lays it out when the guide's height changes, after the
/// guide's frame is valid for that layout pass.
@MainActor
final class HieloKeyboardLayoutProbe: UIView {
  var onLayout: (() -> Void)?

  init() {
    super.init(frame: .zero)
    translatesAutoresizingMaskIntoConstraints = false
    backgroundColor = .clear
    isUserInteractionEnabled = false
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) is unavailable")
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    onLayout?()
  }
}
