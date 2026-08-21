import CoreGraphics

enum KeyboardPopoverDragBehavior {
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
    return verticalDistanceFromTop <= KeyboardPopoverMotion.scrollBoundaryTolerance
  }

  static func predictedEndTranslation(
    translation: CGSize,
    velocity: CGSize
  ) -> CGSize {
    CGSize(
      width: translation.width + velocity.width * KeyboardPopoverMotion.dragPredictionTime,
      height: translation.height + velocity.height * KeyboardPopoverMotion.dragPredictionTime
    )
  }

  static func rubberBandedOffset(for translation: CGSize) -> CGSize {
    CGSize(
      width: rubberBand(
        translation.width,
        limit: KeyboardPopoverMotion.horizontalDragLimit
      ),
      height: rubberBand(
        translation.height,
        limit: translation.height < 0
          ? KeyboardPopoverMotion.upwardDragLimit
          : KeyboardPopoverMotion.downwardDragLimit
      )
    )
  }

  static func scale(for offset: CGSize) -> Double {
    if offset.height < 0 {
      let progress = min(abs(offset.height) / KeyboardPopoverMotion.upwardDragLimit, 1)
      return 1 + progress * (KeyboardPopoverMotion.maximumUpwardDragScale - 1)
    }

    let progress = min(offset.height / KeyboardPopoverMotion.downwardDragLimit, 1)
    return 1 - progress * (1 - KeyboardPopoverMotion.minimumDownwardDragScale)
  }

  static func shouldDismiss(
    translation: CGSize,
    predictedEndTranslation: CGSize
  ) -> Bool {
    translation.height > KeyboardPopoverMotion.dismissalTranslation
      || predictedEndTranslation.height > KeyboardPopoverMotion.dismissalPrediction
  }

  private static func rubberBand(_ value: Double, limit: Double) -> Double {
    let magnitude = abs(value)
    guard magnitude > 0 else { return 0 }
    let resistedMagnitude = limit * (1 - 1 / (magnitude / limit + 1))
    return value < 0 ? -resistedMagnitude : resistedMagnitude
  }
}
