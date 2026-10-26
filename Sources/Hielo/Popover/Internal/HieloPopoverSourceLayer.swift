import SwiftUI

struct HieloPopoverSourceLayer<Content: View>: View {
  let content: Content
  let sourceSize: CGSize
  let containerSize: CGSize
  let expansionProgress: Double

  var body: some View {
    content
      .frame(width: sourceSize.width, height: sourceSize.height)
      .scaleEffect(sourceScale, anchor: .center)
      .position(
        x: containerSize.width / 2,
        y: containerSize.height / 2
      )
      .blur(radius: expansionProgress * HieloPopoverMotion.sourceBlurRadius)
      .opacity(1 - expansionProgress)
      .allowsHitTesting(false)
      .accessibilityHidden(true)
  }

  private var sourceScale: Double {
    min(
      max(1 + expansionProgress * HieloPopoverMotion.sourceScaleIncrease, 1),
      HieloPopoverMotion.maximumSourceScale
    )
  }
}
