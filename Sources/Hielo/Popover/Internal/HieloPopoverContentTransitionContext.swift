import SwiftUI

struct HieloPopoverContentTransitionContext: Equatable, Sendable {
  let surfaceSize: CGSize
  let surfaceCornerRadius: CGFloat
  let isEnabled: Bool
  let rendersSurfaceGlass: Bool

  init(
    surfaceSize: CGSize,
    surfaceCornerRadius: CGFloat = 0,
    isEnabled: Bool,
    rendersSurfaceGlass: Bool = false
  ) {
    self.surfaceSize = surfaceSize
    self.surfaceCornerRadius = surfaceCornerRadius
    self.isEnabled = isEnabled
    self.rendersSurfaceGlass = rendersSurfaceGlass
  }

  func scale(for contentSize: CGSize) -> CGFloat {
    guard isEnabled, contentSize.width > 0, surfaceSize.width > 0 else { return 1 }
    return surfaceSize.width / contentSize.width
  }

  func collapsedContentOpacity(
    collapsedSize: CGSize,
    expandedSize: CGSize
  ) -> Double {
    guard
      let progress = expansionProgress(
        collapsedSize: collapsedSize,
        expandedSize: expandedSize
      )
    else { return 1 }

    return Self.collapsedContentOpacity(at: progress)
  }

  func expandedContentOpacity(
    collapsedSize: CGSize,
    expandedSize: CGSize
  ) -> Double {
    guard
      let progress = expansionProgress(
        collapsedSize: collapsedSize,
        expandedSize: expandedSize
      )
    else { return 0 }

    return Self.expandedContentOpacity(at: progress)
  }

  func expansionProgress(
    collapsedSize: CGSize,
    expandedSize: CGSize
  ) -> Double? {
    guard isEnabled else { return nil }

    let widthDifference = expandedSize.width - collapsedSize.width
    if abs(widthDifference) >= 0.5 {
      return normalizedProgress(
        value: surfaceSize.width,
        collapsedValue: collapsedSize.width,
        difference: widthDifference
      )
    }

    let heightDifference = expandedSize.height - collapsedSize.height
    guard abs(heightDifference) >= 0.5 else { return nil }
    return normalizedProgress(
      value: surfaceSize.height,
      collapsedValue: collapsedSize.height,
      difference: heightDifference
    )
  }

  private func normalizedProgress(
    value: CGFloat,
    collapsedValue: CGFloat,
    difference: CGFloat
  ) -> Double {
    min(max((value - collapsedValue) / difference, 0), 1)
  }

  static func collapsedContentOpacity(at progress: Double) -> Double {
    1 - min(max(progress, 0), 1)
  }

  static func expandedContentOpacity(at progress: Double) -> Double {
    min(max(progress, 0), 1)
  }
}

extension EnvironmentValues {
  @Entry var hieloPopoverContentTransitionContext =
    HieloPopoverContentTransitionContext(
      surfaceSize: .zero,
      surfaceCornerRadius: 0,
      isEnabled: false,
      rendersSurfaceGlass: false
    )
}
