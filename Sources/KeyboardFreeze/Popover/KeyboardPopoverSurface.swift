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
        expandedLayer
        .frame(width: currentSize.width, height: currentSize.height)
        .clipShape(shape)
        .glassEffect(.regular.interactive(), in: shape)
        .modifier(
          KeyboardPopoverSurfaceOpacityModifier(
            progress: expansionProgress,
            fadeFraction: KeyboardPopoverMotion.surfaceFadeFraction
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
    KeyboardPopoverExpandedLayer(
      content: popoverContent,
      destinationSize: destinationSize,
      containerSize: currentSize,
      opacity: expansionProgress
    )
  }

  private var sourceLayer: some View {
    KeyboardPopoverSourceLayer(
      content: sourceContent,
      sourceSize: sourceSize,
      containerSize: currentSize,
      expansionProgress: expansionProgress
    )
  }

}
