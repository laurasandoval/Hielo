import SwiftUI

@Animatable
struct HieloPopoverSurfaceOpacityModifier: ViewModifier {
  var progress: Double
  @AnimatableIgnored var fadeFraction: Double

  func body(content: Content) -> some View {
    content.opacity(
      min(max(progress / fadeFraction, 0), 1)
    )
  }
}
