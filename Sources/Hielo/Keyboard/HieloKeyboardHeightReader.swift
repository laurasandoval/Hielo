import SwiftUI

struct HieloKeyboardHeightReader: UIViewRepresentable {
  let action: (HieloKeyboardHeight) -> Void

  func makeUIView(context: Context) -> HostView {
    HostView(action: action)
  }

  func updateUIView(_ uiView: HostView, context: Context) {
    uiView.action = action
  }

  /// Measures its own keyboard layout guide in window coordinates and delivers changed values.
  ///
  /// A zero-width probe subview is constrained to the guide's vertical
  /// anchors, so a change in the guide's height lays out the probe. The
  /// measured value is delivered on a later main-actor turn, outside the
  /// layout pass, and only when it differs from the last delivered value.
  @MainActor
  final class HostView: UIView {
    var action: (HieloKeyboardHeight) -> Void

    private let probe = HieloKeyboardLayoutProbe()
    private var probeConstraints: [NSLayoutConstraint] = []
    private var height = HieloKeyboardHeight()
    private var deliveredHeight: HieloKeyboardHeight?
    private var delivery: Task<Void, Never>?

    init(action: @escaping (HieloKeyboardHeight) -> Void) {
      self.action = action
      super.init(frame: .zero)
      backgroundColor = .clear
      isUserInteractionEnabled = false
      probe.onLayout = { [weak self] in self?.measure() }
      addSubview(probe)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
      fatalError("init(coder:) is unavailable")
    }

    override func willMove(toWindow newWindow: UIWindow?) {
      super.willMove(toWindow: newWindow)
      NSLayoutConstraint.deactivate(probeConstraints)
      probeConstraints = []
      delivery?.cancel()
      delivery = nil
    }

    override func didMoveToWindow() {
      super.didMoveToWindow()
      guard window != nil else { return }
      let guide = keyboardLayoutGuide
      probeConstraints = [
        probe.leadingAnchor.constraint(equalTo: leadingAnchor),
        probe.widthAnchor.constraint(equalToConstant: 0),
        probe.topAnchor.constraint(equalTo: guide.topAnchor),
        probe.bottomAnchor.constraint(equalTo: guide.bottomAnchor),
      ]
      NSLayoutConstraint.activate(probeConstraints)
      // Measure in the next layout pass, once the guide's frame is valid.
      probe.setNeedsLayout()
    }

    private func measure() {
      guard let window else { return }
      let guideFrame = convert(keyboardLayoutGuide.layoutFrame, to: window)
      let overlap = min(max(window.bounds.maxY - guideFrame.minY, 0), window.bounds.height)
      // Without a docked keyboard, the guide rests on the bottom safe area.
      let isDocked = overlap - window.safeAreaInsets.bottom > 0.5
      height.current = isDocked ? overlap : 0
      if isDocked {
        height.lastVisible = overlap
      }
      scheduleDelivery()
    }

    private func scheduleDelivery() {
      guard delivery == nil, height != deliveredHeight else { return }
      delivery = Task { [weak self] in
        guard !Task.isCancelled else { return }
        self?.deliver()
      }
    }

    private func deliver() {
      delivery = nil
      guard window != nil, height != deliveredHeight else { return }
      deliveredHeight = height
      action(height)
    }
  }
}
