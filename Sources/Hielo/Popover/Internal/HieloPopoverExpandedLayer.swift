import SwiftUI

struct HieloPopoverExpandedLayer<Content: View>: View {
  let content: Content
  let destinationSize: CGSize
  let containerSize: CGSize
  let opacity: Double
  let onSizeChange: (CGSize) -> Void

  var body: some View {
    content
      .fixedSize()
      .onGeometryChange(for: CGSize.self) { $0.size } action: { onSizeChange($0) }
      .frame(width: destinationSize.width, height: destinationSize.height)
      .scaleEffect(contentScale, anchor: .center)
      .opacity(opacity)
      .position(
        x: containerSize.width / 2,
        y: containerSize.height / 2
      )
  }

  private var contentScale: Double {
    guard destinationSize.width > 0 else { return 1 }
    return containerSize.width / destinationSize.width
  }
}
