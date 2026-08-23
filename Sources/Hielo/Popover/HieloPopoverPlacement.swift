import SwiftUI

/// The placement of a presented keyboard popover.
public enum HieloPopoverPlacement: Equatable, Sendable {
  /// Keeps the popover attached to its source using the presentation’s attachment anchor.
  case source

  /// Aligns the popover within the device or window container.
  ///
  /// The first value specifies the alignment point. The inset is measured in
  /// points from the container’s edges and defaults to zero.
  case container(UnitPoint, inset: CGFloat = 0)
}
