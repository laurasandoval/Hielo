import CoreGraphics

enum HieloPopoverDragBehavior {
  static func popoverShouldOwnGesture(
    velocity: CGSize,
    canScrollHorizontally: Bool,
    canScrollVertically: Bool,
    verticalDistanceFromTop: Double
  ) -> Bool {
    if abs(velocity.width) > abs(velocity.height) {
      return !canScrollHorizontally
    }

    guard canScrollVertically else { return true }
    guard velocity.height > 0 else { return false }
    return verticalDistanceFromTop <= HieloPopoverMotion.scrollBoundaryTolerance
  }

  static func predictedEndTranslation(
    translation: CGSize,
    velocity: CGSize
  ) -> CGSize {
    CGSize(
      width: translation.width + velocity.width * HieloPopoverMotion.dragPredictionTime,
      height: translation.height + velocity.height * HieloPopoverMotion.dragPredictionTime
    )
  }

  static func rubberBandedOffset(for translation: CGSize) -> CGSize {
    CGSize(
      width: rubberBand(
        translation.width,
        limit: HieloPopoverMotion.horizontalDragLimit
      ),
      height: rubberBand(
        translation.height,
        limit: translation.height < 0
          ? HieloPopoverMotion.upwardDragLimit
          : HieloPopoverMotion.downwardDragLimit
      )
    )
  }

  static func scale(for offset: CGSize) -> Double {
    if offset.height < 0 {
      let progress = min(abs(offset.height) / HieloPopoverMotion.upwardDragLimit, 1)
      return 1 + progress * (HieloPopoverMotion.maximumUpwardDragScale - 1)
    }

    let progress = min(offset.height / HieloPopoverMotion.downwardDragLimit, 1)
    return 1 - progress * (1 - HieloPopoverMotion.minimumDownwardDragScale)
  }

  static func shouldDismiss(
    translation: CGSize,
    predictedEndTranslation: CGSize
  ) -> Bool {
    translation.height > HieloPopoverMotion.dismissalTranslation
      || predictedEndTranslation.height > HieloPopoverMotion.dismissalPrediction
  }

  private static func rubberBand(_ value: Double, limit: Double) -> Double {
    let magnitude = abs(value)
    guard magnitude > 0 else { return 0 }
    let resistedMagnitude = limit * (1 - 1 / (magnitude / limit + 1))
    return value < 0 ? -resistedMagnitude : resistedMagnitude
  }
}
