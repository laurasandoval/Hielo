import SwiftUI

extension View {
  /// Performs an action when the docked keyboard's height changes.
  ///
  /// Like `onGeometryChange(for:of:action:)`, this modifier calls `action`
  /// only when the value changes, so updating state from it doesn't
  /// invalidate views for every layout pass. It calls `action` with the
  /// initial value when the view first enters a window, stops reporting while
  /// the view is outside a window, and on reentry reports a value that changed
  /// while it was away. Each modifier keeps its own
  /// ``HieloKeyboardHeight/lastVisible`` value.
  ///
  /// ```swift
  /// @State private var keyboard = HieloKeyboardHeight()
  ///
  /// var body: some View {
  ///     MessageList()
  ///         .safeAreaInset(edge: .bottom) { Composer() }
  ///         .onHieloKeyboardHeightChange { keyboard = $0 }
  /// }
  /// ```
  ///
  /// Heights measure the keyboard's overlap with the bottom of the window,
  /// including the bottom safe-area region it covers. Subtract the bottom
  /// safe-area inset for layout that already respects the safe area. A sheet
  /// detent's height is likewise measured within the sheet's safe area, so an
  /// edge-attached sheet whose top meets the keyboard's former top edge uses
  /// `.height(keyboard.lastVisible - bottomSafeAreaInset)`.
  ///
  /// The modifier reads its own view's `keyboardLayoutGuide` with its default
  /// configuration and uses no private API. Values follow that guide:
  ///
  /// - Floating, undocked, and split keyboards report a `current` of `0`.
  /// - With a hardware keyboard, the docked shortcuts bar reports its overlap;
  ///   with no bar, `current` is `0`.
  /// - An overlap no taller than the window's bottom safe-area inset reports
  ///   `0`, because the guide rests there when no keyboard is shown.
  /// - Ordinary show and hide animations report their final value once, when
  ///   the animation starts, rather than once per frame.
  /// - Interactive dismissal, such as with
  ///   `scrollDismissesKeyboard(.interactively)`, reports values as the guide
  ///   tracks the keyboard.
  ///
  /// `action` runs on the main actor after the layout pass that produced the
  /// value, so it can update state without modifying it during a view update.
  ///
  /// - Parameter action: A closure to run with the new keyboard height.
  /// - Returns: A view that reports keyboard height changes.
  public func onHieloKeyboardHeightChange(
    _ action: @escaping (HieloKeyboardHeight) -> Void
  ) -> some View {
    background(HieloKeyboardHeightReader(action: action))
  }
}
