import SwiftUI

struct KeyboardPopoverPlacement {
  static func adaptiveAttachmentAnchor(
    preferredAnchor: UnitPoint,
    sourceFrame: CGRect,
    windowBounds: CGRect
  ) -> UnitPoint {
    UnitPoint(
      x: resolvedComponent(
        preferredAnchor.x,
        sourceMidpoint: sourceFrame.midX,
        windowMidpoint: windowBounds.midX
      ),
      y: resolvedComponent(
        preferredAnchor.y,
        sourceMidpoint: sourceFrame.midY,
        windowMidpoint: windowBounds.midY
      )
    )
  }

  static func destinationFrame(
    sourceFrame: CGRect,
    destinationSize: CGSize,
    attachmentAnchor: UnitPoint,
    windowBounds: CGRect
  ) -> CGRect {
    let attachment = CGPoint(
      x: sourceFrame.minX + sourceFrame.width * attachmentAnchor.x,
      y: sourceFrame.minY + sourceFrame.height * attachmentAnchor.y
    )
    let proposedOrigin = CGPoint(
      x: attachment.x - destinationSize.width * attachmentAnchor.x,
      y: attachment.y - destinationSize.height * attachmentAnchor.y
    )
    let maximumOrigin = CGPoint(
      x: max(windowBounds.minX, windowBounds.maxX - destinationSize.width),
      y: max(windowBounds.minY, windowBounds.maxY - destinationSize.height)
    )
    let origin = CGPoint(
      x: min(max(proposedOrigin.x, windowBounds.minX), maximumOrigin.x),
      y: min(max(proposedOrigin.y, windowBounds.minY), maximumOrigin.y)
    )

    return CGRect(origin: origin, size: destinationSize)
  }

  private static func resolvedComponent(
    _ preferredComponent: Double,
    sourceMidpoint: Double,
    windowMidpoint: Double
  ) -> Double {
    guard abs(preferredComponent - 0.5) < 0.001 else {
      return preferredComponent
    }
    return sourceMidpoint <= windowMidpoint ? 0 : 1
  }
}
