import SwiftUI

/// Hosts a session's pinned keyboard snapshot at the bottom of moving content.
struct KeyboardFreezePinnedKeyboard: UIViewRepresentable {
  private let keyboardFreeze: KeyboardFreeze

  init(keyboardFreeze: KeyboardFreeze) {
    self.keyboardFreeze = keyboardFreeze
  }

  func makeUIView(context: Context) -> UIView {
    HostView(keyboardFreeze: keyboardFreeze)
  }

  func updateUIView(_ uiView: UIView, context: Context) {
    guard let hostView = uiView as? HostView else { return }
    hostView.keyboardFreeze = keyboardFreeze
    hostView.setNeedsLayout()
    hostView.layoutIfNeeded()
  }

  @MainActor
  private final class HostView: UIView {
    var keyboardFreeze: KeyboardFreeze

    init(keyboardFreeze: KeyboardFreeze) {
      self.keyboardFreeze = keyboardFreeze
      super.init(frame: .zero)
      backgroundColor = .clear
      isUserInteractionEnabled = false
      clipsToBounds = false
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
      fatalError("init(coder:) is unavailable")
    }

    override func didMoveToWindow() {
      super.didMoveToWindow()
      setNeedsLayout()
    }

    override func safeAreaInsetsDidChange() {
      super.safeAreaInsetsDidChange()
      setNeedsLayout()
    }

    override func layoutSubviews() {
      super.layoutSubviews()
      keyboardFreeze.layoutPageSnapshot(in: self)
    }
  }
}
