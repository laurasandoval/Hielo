import SwiftUI

struct KeyboardPopoverSourceLayer<Content: View>: View {
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
      .blur(radius: expansionProgress * 8)
      .opacity(1 - expansionProgress)
      .allowsHitTesting(false)
      .accessibilityHidden(true)
  }

  private var sourceScale: Double {
    min(max(1 + expansionProgress * 0.5, 1), 1.5)
  }
}
