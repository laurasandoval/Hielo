import SwiftUI

struct KeyboardPopoverSurface<SourceContent: View, PopoverContent: View>: View {
  let sourceContent: SourceContent
  let popoverContent: PopoverContent
  let sourceSize: CGSize
  let destinationSize: CGSize
  let currentSize: CGSize
  let shape: UnevenRoundedRectangle
  let expansionProgress: Double
  let fadesSurface: Bool

  var body: some View {
    if fadesSurface {
      ZStack {
        KeyboardPopoverExpandedLayer(
          content: popoverContent,
          destinationSize: destinationSize,
          containerSize: currentSize,
          opacity: 1
        )
        .frame(width: currentSize.width, height: currentSize.height)
        .clipShape(shape)
        .glassEffect(.regular.interactive(), in: shape)
        .modifier(
          KeyboardPopoverSurfaceOpacityModifier(
            progress: expansionProgress,
            fadeFraction: 0.25
          )
        )

        KeyboardPopoverSourceLayer(
          content: sourceContent,
          sourceSize: sourceSize,
          containerSize: currentSize,
          expansionProgress: expansionProgress
        )
      }
      .frame(width: currentSize.width, height: currentSize.height)
    } else {
      ZStack {
        KeyboardPopoverSourceLayer(
          content: sourceContent,
          sourceSize: sourceSize,
          containerSize: currentSize,
          expansionProgress: expansionProgress
        )

        KeyboardPopoverExpandedLayer(
          content: popoverContent,
          destinationSize: destinationSize,
          containerSize: currentSize,
          opacity: expansionProgress
        )
      }
      .frame(width: currentSize.width, height: currentSize.height)
      .clipShape(shape)
      .glassEffect(.regular.interactive(), in: shape)
    }
  }
}
