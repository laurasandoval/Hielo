import SwiftUI

/// The appearance and transition of a keyboard popover’s source.
public enum KeyboardPopoverStyle: Sendable {
  /// An interactive glass source that morphs into the popover. The default style.
  case glass

  /// A source without added glass, with a fading popover surface.
  case plain
}

extension EnvironmentValues {
  @Entry var keyboardPopoverStyle: KeyboardPopoverStyle = .glass
}
