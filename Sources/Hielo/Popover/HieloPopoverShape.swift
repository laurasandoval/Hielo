import SwiftUI

/// The shape of a keyboard popover or its source view.
///
/// Use these values with the `sourceShape` and `popoverShape` parameters of
/// `hieloPopover` to configure the endpoints of the presentation transition.
public struct HieloPopoverShape: Shape, Sendable {
  private let shape: AnyShape
  private let resolveCornerRadii: @Sendable (CGSize) -> RectangleCornerRadii

  private init<Content: Shape>(
    shape: Content,
    resolveCornerRadii: @escaping @Sendable (CGSize) -> RectangleCornerRadii
  ) {
    self.shape = AnyShape(shape)
    self.resolveCornerRadii = resolveCornerRadii
  }

  /// A capsule whose radius follows the shape's size.
  public static let capsule = HieloPopoverShape(
    shape: Capsule(style: .continuous)
  ) { size in
    uniformCornerRadii(min(size.width, size.height) / 2)
  }

  /// A circle centered in the shape's bounds.
  public static let circle = HieloPopoverShape(shape: Circle()) { size in
    uniformCornerRadii(min(size.width, size.height) / 2)
  }

  /// A rectangle with square corners.
  public static let rect = HieloPopoverShape(shape: Rectangle()) { _ in
    uniformCornerRadii(0)
  }

  /// Creates a continuously rounded rectangle with a uniform corner radius.
  ///
  /// - Parameter cornerRadius: The radius in points. Negative values are treated as zero.
  /// - Returns: A rounded rectangular popover shape.
  public static func rect(cornerRadius: CGFloat) -> HieloPopoverShape {
    let radius = max(cornerRadius, 0)
    return HieloPopoverShape(
      shape: RoundedRectangle(cornerRadius: radius, style: .continuous)
    ) { _ in
      uniformCornerRadii(radius)
    }
  }

  /// Creates a continuously rounded rectangle with independently configured corners.
  ///
  /// - Parameter cornerRadii: The radius of each corner, in points.
  /// - Returns: A popover shape with the specified corner radii.
  public static func rect(
    cornerRadii: RectangleCornerRadii
  ) -> HieloPopoverShape {
    HieloPopoverShape(
      shape: UnevenRoundedRectangle(
        cornerRadii: cornerRadii,
        style: .continuous
      )
    ) { _ in
      cornerRadii
    }
  }

  /// Returns the shape’s path in the specified rectangle.
  ///
  /// - Parameter rect: The bounds in which to draw the shape.
  /// - Returns: A path describing the shape within those bounds.
  nonisolated public func path(in rect: CGRect) -> Path {
    shape.path(in: rect)
  }

  func cornerRadii(for size: CGSize) -> RectangleCornerRadii {
    resolveCornerRadii(size)
  }

  private static func uniformCornerRadii(_ radius: CGFloat) -> RectangleCornerRadii {
    RectangleCornerRadii(
      topLeading: radius,
      bottomLeading: radius,
      bottomTrailing: radius,
      topTrailing: radius
    )
  }
}
