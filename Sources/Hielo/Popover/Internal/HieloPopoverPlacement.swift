import SwiftUI

struct HieloPopoverPlacement {
  static func adaptiveAttachmentAnchor(
    preferredAnchor: UnitPoint,
    sourceFrame: CGRect,
    availableBounds: CGRect
  ) -> UnitPoint {
    UnitPoint(
      x: resolvedComponent(
        preferredAnchor.x,
        sourceMidpoint: sourceFrame.midX,
        availableMidpoint: availableBounds.midX
      ),
      y: resolvedComponent(
        preferredAnchor.y,
        sourceMidpoint: sourceFrame.midY,
        availableMidpoint: availableBounds.midY
      )
    )
  }

  static func destinationFrame(
    sourceFrame: CGRect,
    destinationSize: CGSize,
    attachmentAnchor: UnitPoint,
    availableBounds: CGRect
  ) -> CGRect {
    let attachment = CGPoint(
      x: sourceFrame.minX + sourceFrame.width * attachmentAnchor.x,
      y: sourceFrame.minY + sourceFrame.height * attachmentAnchor.y
    )
    let proposedOrigin = CGPoint(
      x: attachment.x - destinationSize.width * attachmentAnchor.x,
      y: attachment.y - destinationSize.height * attachmentAnchor.y
    )
    let origin = CGPoint(
      x: constrainedOrigin(
        proposedOrigin.x,
        length: destinationSize.width,
        availableRange: availableBounds.minX...availableBounds.maxX
      ),
      y: constrainedOrigin(
        proposedOrigin.y,
        length: destinationSize.height,
        availableRange: availableBounds.minY...availableBounds.maxY
      )
    )

    return CGRect(origin: origin, size: destinationSize)
  }

  private static func resolvedComponent(
    _ preferredComponent: Double,
    sourceMidpoint: Double,
    availableMidpoint: Double
  ) -> Double {
    guard abs(preferredComponent - 0.5) < 0.001 else {
      return preferredComponent
    }
    return sourceMidpoint <= availableMidpoint ? 0 : 1
  }

  private static func constrainedOrigin(
    _ proposedOrigin: Double,
    length: Double,
    availableRange: ClosedRange<Double>
  ) -> Double {
    let maximumOrigin = max(
      availableRange.lowerBound,
      availableRange.upperBound - length
    )
    return min(
      max(proposedOrigin, availableRange.lowerBound),
      maximumOrigin
    )
  }
}
