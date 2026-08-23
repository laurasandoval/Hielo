import UIKit

@MainActor
final class HieloPopoverCornerRadiusResolver {
  private weak var containerView: UIView?

  func connect(to containerView: UIView) {
    self.containerView = containerView
  }

  func resolve(
    _ cornerRadius: HieloPopoverCornerRadius,
    for frame: CGRect
  ) -> CGFloat? {
    switch cornerRadius {
    case .fixed(let radius):
      max(radius, 0)
    case .containerConcentric:
      resolveContainerConcentricRadius(for: frame)
    }
  }

  private func resolveContainerConcentricRadius(
    for frame: CGRect
  ) -> CGFloat? {
    guard let containerView, !frame.isEmpty else { return nil }

    let probe = UIView(frame: frame)
    probe.isUserInteractionEnabled = false
    probe.cornerConfiguration = .uniformCorners(
      radius: .containerConcentric()
    )
    containerView.addSubview(probe)
    probe.layoutIfNeeded()
    let radius = probe.effectiveRadius(corner: .allCorners)
    probe.removeFromSuperview()
    return radius.isFinite ? radius : nil
  }
}
