import SwiftUI

struct HieloPopoverTransitionSurfaceModifier: ViewModifier {
  let isEnabled: Bool
  let cornerRadius: CGFloat

  func body(content: Content) -> some View {
    let shape = UnevenRoundedRectangle(
      cornerRadii: RectangleCornerRadii(
        topLeading: cornerRadius,
        bottomLeading: cornerRadius,
        bottomTrailing: cornerRadius,
        topTrailing: cornerRadius
      ),
      style: .continuous
    )

    content
      .clipShape(shape)
      .glassEffect(isEnabled ? .regular.interactive() : .identity, in: shape)
      .glassEffectTransition(.identity)
  }
}
