import SwiftUI

struct HieloPopoverShapeTransition: Sendable {
  let sourceShape: HieloPopoverShape
  let popoverShape: HieloPopoverShape

  static let standard = HieloPopoverShapeTransition(
    sourceShape: .capsule,
    popoverShape: .rect(cornerRadius: 32)
  )

  func resolve(
    sourceSize: CGSize,
    destinationSize: CGSize,
    expansionProgress: Double
  ) -> RectangleCornerRadii {
    let sourceCorners = sourceShape.cornerRadii(for: sourceSize)
    let popoverCorners = popoverShape.cornerRadii(for: destinationSize)
    let progress = CGFloat(min(max(expansionProgress, 0), 1))

    return RectangleCornerRadii(
      topLeading: interpolate(
        sourceCorners.topLeading,
        popoverCorners.topLeading,
        progress: progress
      ),
      bottomLeading: interpolate(
        sourceCorners.bottomLeading,
        popoverCorners.bottomLeading,
        progress: progress
      ),
      bottomTrailing: interpolate(
        sourceCorners.bottomTrailing,
        popoverCorners.bottomTrailing,
        progress: progress
      ),
      topTrailing: interpolate(
        sourceCorners.topTrailing,
        popoverCorners.topTrailing,
        progress: progress
      )
    )
  }

  func resolveShape(
    sourceSize: CGSize,
    destinationSize: CGSize,
    expansionProgress: Double
  ) -> UnevenRoundedRectangle {
    UnevenRoundedRectangle(
      cornerRadii: resolve(
        sourceSize: sourceSize,
        destinationSize: destinationSize,
        expansionProgress: expansionProgress
      ),
      style: .continuous
    )
  }

  private func interpolate(
    _ source: CGFloat,
    _ destination: CGFloat,
    progress: CGFloat
  ) -> CGFloat {
    source + (destination - source) * progress
  }
}
