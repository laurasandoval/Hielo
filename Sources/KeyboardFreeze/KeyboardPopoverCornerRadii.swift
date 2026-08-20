import SwiftUI

struct KeyboardPopoverCornerRadii: Sendable {
  enum Radius: Sendable {
    case capsule
    case fixed(Double)

    var shape: AnyShape {
      switch self {
      case .capsule:
        AnyShape(Capsule())
      case .fixed(let radius):
        AnyShape(RoundedRectangle(cornerRadius: radius))
      }
    }

    func resolve(for size: CGSize) -> Double {
      let maximumRadius = min(size.width, size.height) / 2
      switch self {
      case .capsule:
        return maximumRadius
      case .fixed(let radius):
        return min(max(radius, 0), maximumRadius)
      }
    }
  }

  static let standard = KeyboardPopoverCornerRadii(
    collapsed: .capsule,
    expanded: .fixed(32)
  )

  let collapsed: Radius
  let expanded: Radius

  func resolve(
    sourceSize: CGSize,
    destinationSize: CGSize,
    expansionProgress: Double
  ) -> Double {
    let collapsedRadius = collapsed.resolve(for: sourceSize)
    let expandedRadius = expanded.resolve(for: destinationSize)
    return collapsedRadius
      + (expandedRadius - collapsedRadius) * expansionProgress
  }
}
