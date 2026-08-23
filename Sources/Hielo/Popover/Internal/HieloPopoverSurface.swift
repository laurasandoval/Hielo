import SwiftUI

struct HieloPopoverSurface<SourceContent: View, PopoverContent: View>: View {
  let sourceContent: SourceContent
  let popoverContent: PopoverContent
  let sourceSize: CGSize
  let destinationSize: CGSize
  let currentSize: CGSize
  let shape: UnevenRoundedRectangle
  let cornerRadius: CGFloat
  let expansionProgress: Double
  let fadesSurface: Bool
  let scalesTransitionContent: Bool
  let rendersTransitionSurfaces: Bool
  let onContentSizeChange: (CGSize) -> Void

  var body: some View {
    GlassEffectContainer(spacing: 0) {
      if fadesSurface {
        ZStack {
          expandedLayer
          .frame(width: currentSize.width, height: currentSize.height)
          .modifier(
            HieloPopoverOuterSurfaceModifier(
              isEnabled: !rendersTransitionSurfaces,
              shape: shape
            )
          )
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
        .modifier(
          HieloPopoverOuterSurfaceModifier(
            isEnabled: !rendersTransitionSurfaces,
            shape: shape
          )
        )
      }
    }
  }

  private var expandedLayer: some View {
    HieloPopoverExpandedLayer(
      content: popoverContent,
      destinationSize: destinationSize,
      containerSize: currentSize,
      surfaceCornerRadius: cornerRadius,
      opacity: expansionProgress,
      scalesTransitionContent: scalesTransitionContent,
      rendersTransitionSurfaces: rendersTransitionSurfaces,
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
