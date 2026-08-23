import SwiftUI

@Animatable
struct HieloPopoverContentOpacityModifier: ViewModifier {
  var progress: Double
  @AnimatableIgnored var role: HieloPopoverContentTransitionRole

  func body(content: Content) -> some View {
    content.opacity(opacity)
  }

  private var opacity: Double {
    switch role {
    case .collapsed:
      return HieloPopoverContentTransitionContext.collapsedContentOpacity(at: progress)
    case .expanded:
      return HieloPopoverContentTransitionContext.expandedContentOpacity(at: progress)
    }
  }
}
