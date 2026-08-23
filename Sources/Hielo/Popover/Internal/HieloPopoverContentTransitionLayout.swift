import SwiftUI

struct HieloPopoverContentTransitionLayout: Layout {
  let isExpanded: Bool

  func sizeThatFits(
    proposal: ProposedViewSize,
    subviews: Subviews,
    cache: inout ()
  ) -> CGSize {
    guard subviews.count == 2 else { return .zero }
    return subviews[isExpanded ? 1 : 0].sizeThatFits(.unspecified)
  }

  func placeSubviews(
    in bounds: CGRect,
    proposal: ProposedViewSize,
    subviews: Subviews,
    cache: inout ()
  ) {
    let center = CGPoint(x: bounds.midX, y: bounds.midY)

    for subview in subviews {
      let size = subview.sizeThatFits(.unspecified)
      subview.place(
        at: center,
        anchor: .center,
        proposal: ProposedViewSize(size)
      )
    }
  }
}
