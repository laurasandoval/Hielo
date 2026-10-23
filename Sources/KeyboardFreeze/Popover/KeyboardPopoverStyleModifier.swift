import SwiftUI

extension View {
  /// Sets the source style for keyboard popovers within this view.
  ///
  /// Apply this modifier after `keyboardPopover` or to an ancestor. The default
  /// style is `.glass`. Use `.plain` for a button embedded in a glass composer.
  /// This style controls the source; the presented popover still uses glass.
  ///
  /// - Parameter style: The source appearance and transition to use.
  /// - Returns: A view that supplies the style to its keyboard popovers.
  public func keyboardPopoverStyle(_ style: KeyboardPopoverStyle) -> some View {
    environment(\.keyboardPopoverStyle, style)
  }
}
