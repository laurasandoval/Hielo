import SwiftUI

struct HieloPopoverOuterSurfaceModifier: ViewModifier {
  let isEnabled: Bool
  let shape: UnevenRoundedRectangle

  func body(content: Content) -> some View {
    content
      .clipShape(shape)
      .glassEffect(isEnabled ? .regular.interactive() : .identity, in: shape)
      .glassEffectTransition(.identity)
  }
}
