import SwiftUI

struct KeyboardFreezeSourceReader: UIViewRepresentable {
  let source: KeyboardFreezeSource

  func makeUIView(context: Context) -> HostView {
    HostView(source: source)
  }

  func updateUIView(_ uiView: HostView, context: Context) {
    uiView.source = source
    uiView.setNeedsLayout()
  }

  @MainActor
  final class HostView: UIView {
    var source: KeyboardFreezeSource {
      didSet {
        guard oldValue !== source else { return }
        oldValue.clear(owner: self)
        updateSource()
      }
    }

    init(source: KeyboardFreezeSource) {
      self.source = source
      super.init(frame: .zero)
      backgroundColor = .clear
      isUserInteractionEnabled = false
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
      fatalError("init(coder:) is unavailable")
    }

    override func didMoveToWindow() {
      super.didMoveToWindow()
      if window == nil {
        source.clear(owner: self)
      } else {
        updateSource()
      }
    }

    override func layoutSubviews() {
      super.layoutSubviews()
      updateSource()
    }

    private func updateSource() {
      guard let screen = window?.screen else { return }
      source.update(
        frameInScreen: convert(bounds, to: nil),
        screen: screen,
        owner: self
      )
    }
  }
}
