import Foundation

enum KeyboardPopoverMotion {
  static let geometrySettleDelay = Duration.milliseconds(16)
  static let surfaceFadeFraction = 0.05
  static let sourceBlurRadius = 16.0
  static let sourceScaleIncrease = 0.5
  static let maximumSourceScale = 1.2

  static let dragPredictionTime = 0.2
  static let scrollBoundaryTolerance = 1.0
  static let horizontalDragLimit = 44.0
  static let upwardDragLimit = 36.0
  static let downwardDragLimit = 80.0
  static let maximumUpwardDragScale = 1.05
  static let minimumDownwardDragScale = 0.9
  static let dismissalTranslation = 64.0
  static let dismissalPrediction = 120.0
}
