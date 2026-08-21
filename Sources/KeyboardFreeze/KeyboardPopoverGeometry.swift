import SwiftUI

struct KeyboardPopoverGeometry {
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

  static func rubberBandedOffset(for translation: CGSize) -> CGSize {
    CGSize(
      width: rubberBand(translation.width, limit: 44),
      height: rubberBand(
        translation.height,
        limit: translation.height < 0 ? 36 : 80
      )
    )
  }

  static func dragScale(for offset: CGSize) -> Double {
    if offset.height < 0 {
      1 + min(abs(offset.height) / 36, 1) * 0.05
    } else {
      1 - min(offset.height / 80, 1) * 0.1
    }
  }

  static func shouldDismiss(
    translation: CGSize,
    predictedEndTranslation: CGSize
  ) -> Bool {
    translation.height > 64 || predictedEndTranslation.height > 120
  }

  private static func rubberBand(_ value: Double, limit: Double) -> Double {
    let magnitude = abs(value)
    guard magnitude > 0 else { return 0 }
    let resistedMagnitude = limit * (1 - 1 / (magnitude / limit + 1))
    return value < 0 ? -resistedMagnitude : resistedMagnitude
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
