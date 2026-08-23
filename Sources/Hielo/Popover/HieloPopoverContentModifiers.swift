import SwiftUI

extension View {
  /// Requests a fixed corner radius for the enclosing keyboard popover.
  ///
  /// Apply this modifier to the popover’s content, rather than its source view.
  ///
  /// ```swift
  /// Text("Menu")
  ///     .padding()
  ///     .hieloPopoverCornerRadius(24)
  /// ```
  ///
  /// - Parameter radius: The corner radius, in points.
  /// - Returns: A view that requests the specified popover corner radius.
  public func hieloPopoverCornerRadius(_ radius: CGFloat) -> some View {
    hieloPopoverCornerRadius(.fixed(radius))
  }

  /// Configures the corner-radius behavior of the enclosing keyboard popover.
  ///
  /// Apply this modifier inside the popover’s content. Use `.fixed(_:)` for a
  /// specific radius, or `.containerConcentric` for a radius derived from the
  /// popover’s position within its device or window container.
  ///
  /// - Parameter cornerRadius: The corner-radius behavior to request.
  /// - Returns: A view that configures its enclosing popover’s corners.
  public func hieloPopoverCornerRadius(
    _ cornerRadius: HieloPopoverCornerRadius
  ) -> some View {
    preference(
      key: HieloPopoverCornerRadiusPreferenceKey.self,
      value: cornerRadius
    )
  }

  /// Controls whether people can dismiss the enclosing keyboard popover by dragging.
  ///
  /// Apply this modifier to the popover’s content. Disabling drag dismissal
  /// still allows outside-tap and programmatic dismissal.
  ///
  /// - Parameter isDisabled: Whether drag dismissal is disabled. The default is `true`.
  /// - Returns: A view that configures drag dismissal for its enclosing popover.
  public func hieloPopoverDragDismissDisabled(
    _ isDisabled: Bool = true
  ) -> some View {
    preference(
      key: HieloPopoverDragDismissDisabledPreferenceKey.self,
      value: isDisabled
    )
  }

  /// Requests a placement for the enclosing keyboard popover.
  ///
  /// Apply this modifier to the popover’s content. Use `.source` to keep the
  /// popover attached to its source, or `.container(_:inset:)` to position it
  /// within the presentation container.
  ///
  /// ```swift
  /// Text("Details")
  ///     .frame(width: 300, height: 450)
  ///     .hieloPopoverPlacement(.container(.bottom, inset: 8))
  /// ```
  ///
  /// - Parameter placement: The placement to request.
  /// - Returns: A view that configures the placement of its enclosing popover.
  public func hieloPopoverPlacement(
    _ placement: HieloPopoverPlacement
  ) -> some View {
    preference(
      key: HieloPopoverPlacementPreferenceKey.self,
      value: placement
    )
  }
}
