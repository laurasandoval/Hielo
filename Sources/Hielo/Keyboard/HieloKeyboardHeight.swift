import CoreGraphics

/// The height of the docked software keyboard, and the height it last had while visible.
///
/// Heights are in points and measure how far the keyboard overlaps the bottom
/// of the view's window: the distance from the window's bottom edge to the
/// keyboard's top edge, including the bottom safe-area region the keyboard
/// covers. On an iPhone with a home indicator, a keyboard whose top edge is
/// 336 points above the bottom of the window reports `336`, not `336` minus
/// the 34-point bottom inset.
///
/// Receive values with `onHieloKeyboardHeightChange(_:)`.
public struct HieloKeyboardHeight: Equatable, Sendable {
  /// The current overlap of a docked keyboard with the bottom of the window.
  ///
  /// The value is `0` when no docked keyboard overlaps the window, including
  /// while a floating, undocked, or split keyboard is shown.
  public var current: CGFloat

  /// The most recent nonzero ``current`` value.
  ///
  /// The value keeps the keyboard's last visible height after it is dismissed
  /// and is `0` until a docked keyboard has appeared.
  public var lastVisible: CGFloat

  /// Creates a keyboard height.
  ///
  /// - Parameters:
  ///   - current: The current keyboard overlap. The default is `0`.
  ///   - lastVisible: The most recent nonzero overlap. The default is `0`.
  public init(current: CGFloat = 0, lastVisible: CGFloat = 0) {
    self.current = current
    self.lastVisible = lastVisible
  }
}

extension HieloKeyboardHeight {
  /// Records the keyboard layout guide's measured overlap with the window bottom.
  ///
  /// Without a docked keyboard, the guide rests on the bottom safe area, so an
  /// overlap no larger than the inset counts as no keyboard.
  mutating func update(overlap: CGFloat, bottomSafeAreaInset: CGFloat) {
    let isDocked = overlap - bottomSafeAreaInset > 0.5
    current = isDocked ? overlap : 0
    if isDocked {
      lastVisible = overlap
    }
  }
}
