import CoreGraphics

/// The corner-radius behavior of a presented keyboard popover.
public enum HieloPopoverCornerRadius: Equatable, Sendable {
  /// A continuously rounded rectangle with the specified radius in points.
  case fixed(CGFloat)

  /// A radius derived from the popover’s position within its device or window container.
  ///
  /// Use this value for presentations that should follow the container’s corners
  /// as their size or placement changes.
  case containerConcentric
}
