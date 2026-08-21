import SwiftUI

extension View {
  /// Marks this view as an overlay source without requiring manual coordinates.
  public func keyboardFreezeSource(_ source: KeyboardFreezeSource) -> some View {
    background(KeyboardFreezeSourceReader(source: source))
  }
}
