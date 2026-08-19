import UIKit

@MainActor
final class PopoverPositioningView: UIView {
  private var displayLink: CADisplayLink?

  var targetFrame: CGRect {
    didSet {
      positionPopover()
    }
  }

  init(targetFrame: CGRect) {
    self.targetFrame = targetFrame
    super.init(frame: .zero)
    isUserInteractionEnabled = false
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) is unavailable")
  }

  override func didMoveToWindow() {
    super.didMoveToWindow()
    if window == nil {
      stopPositioning()
    } else {
      startPositioning()
    }
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    positionPopover()
  }

  private func startPositioning() {
    guard displayLink == nil else { return }
    let displayLink = CADisplayLink(
      target: self,
      selector: #selector(positionPopover)
    )
    displayLink.add(to: .main, forMode: .common)
    self.displayLink = displayLink
  }

  private func stopPositioning() {
    displayLink?.invalidate()
    displayLink = nil
  }

  @objc private func positionPopover() {
    guard let popoverView = popoverContainer() else { return }
    let bounds = popoverView.superview?.bounds ?? window?.bounds ?? .zero
    let inset: CGFloat = 12
    popoverView.frame = CGRect(
      x: min(max(targetFrame.minX, inset), bounds.maxX - targetFrame.width - inset),
      y: min(max(targetFrame.minY, inset), bounds.maxY - targetFrame.height - inset),
      width: targetFrame.width,
      height: targetFrame.height
    )
  }

  private func popoverContainer() -> UIView? {
    var ancestor = superview
    var container: UIView?
    while let view = ancestor {
      let matchesContentSize =
        abs(view.bounds.width - targetFrame.width) < 1
        && abs(view.bounds.height - targetFrame.height) < 1
      guard matchesContentSize else {
        break
      }
      container = view
      ancestor = view.superview
    }
    return container
  }
}
