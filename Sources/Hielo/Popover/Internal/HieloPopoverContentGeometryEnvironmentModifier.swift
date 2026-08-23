import SwiftUI

@Animatable
struct HieloPopoverContentGeometryEnvironmentModifier: ViewModifier {
  var surfaceSize: CGSize
  var surfaceCornerRadius: CGFloat
  @AnimatableIgnored var isEnabled: Bool
  @AnimatableIgnored var rendersSurfaceGlass: Bool

  func body(content: Content) -> some View {
    content.environment(
      \.hieloPopoverContentTransitionContext,
      HieloPopoverContentTransitionContext(
        surfaceSize: surfaceSize,
        surfaceCornerRadius: surfaceCornerRadius,
        isEnabled: isEnabled,
        rendersSurfaceGlass: rendersSurfaceGlass
      )
    )
  }
}
