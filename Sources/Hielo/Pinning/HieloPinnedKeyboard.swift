import SwiftUI

/// Hosts a session's pinned keyboard snapshot at the bottom of moving content.
struct HieloPinnedKeyboard: UIViewRepresentable {
  private let session: HieloSession

  init(session: HieloSession) {
    self.session = session
  }

  func makeUIView(context: Context) -> UIView {
    HostView(session: session)
  }

  func updateUIView(_ uiView: UIView, context: Context) {
    guard let hostView = uiView as? HostView else { return }
    hostView.session = session
    hostView.setNeedsLayout()
    hostView.layoutIfNeeded()
  }

  @MainActor
  private final class HostView: UIView {
    var session: HieloSession

    init(session: HieloSession) {
      self.session = session
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
      session.layoutPageSnapshot(in: self)
    }
  }
}
