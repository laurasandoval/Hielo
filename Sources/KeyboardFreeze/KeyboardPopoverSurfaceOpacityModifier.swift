import SwiftUI

@Animatable
struct KeyboardPopoverSurfaceOpacityModifier: ViewModifier {
  var progress: Double
  @AnimatableIgnored var fadeFraction: Double

  func body(content: Content) -> some View {
    content.opacity(
      min(max(progress / fadeFraction, 0), 1)
    )
  }
}
