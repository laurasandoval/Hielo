import SwiftUI

struct HieloPopoverSurface<SourceContent: View, PopoverContent: View>: View {
  let sourceContent: SourceContent
  let popoverContent: PopoverContent
  let sourceSize: CGSize
  let destinationSize: CGSize
  let currentSize: CGSize
  let shape: UnevenRoundedRectangle
  let expansionProgress: Double
  let fadesSurface: Bool
  let onContentSizeChange: (CGSize) -> Void

  var body: some View {
    if fadesSurface {
      ZStack {
        expandedLayer
          .frame(width: currentSize.width, height: currentSize.height)
          .clipShape(shape)
          .glassEffect(.regular.interactive(), in: shape)
          .modifier(
            HieloPopoverSurfaceOpacityModifier(
              progress: expansionProgress,
              fadeFraction: HieloPopoverMotion.surfaceFadeFraction
            )
          )

        sourceLayer
      }
      .frame(width: currentSize.width, height: currentSize.height)
    } else {
      ZStack {
        sourceLayer

        expandedLayer
      }
      .frame(width: currentSize.width, height: currentSize.height)
      .clipShape(shape)
      .glassEffect(.regular.interactive(), in: shape)
    }
  }

  private var expandedLayer: some View {
    HieloPopoverExpandedLayer(
      content: popoverContent,
      destinationSize: destinationSize,
      containerSize: currentSize,
      opacity: expansionProgress,
      onSizeChange: onContentSizeChange
    )
  }

  private var sourceLayer: some View {
    HieloPopoverSourceLayer(
      content: sourceContent,
      sourceSize: sourceSize,
      containerSize: currentSize,
      expansionProgress: expansionProgress
    )
  }

}
