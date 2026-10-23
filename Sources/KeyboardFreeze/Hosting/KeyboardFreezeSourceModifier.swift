import SwiftUI

extension View {
  /// Associates this view with a source for overlay positioning.
  ///
  /// Use this modifier when presenting an overlay directly through a
  /// ``KeyboardFreeze`` session. It tracks the view’s screen position so you
  /// can pass the source to the session without calculating coordinates.
  ///
  /// - Parameter source: The source that tracks this view. Use a separate source
  ///   for each view you want to track.
  /// - Returns: A view that updates the source as its geometry changes.
  public func keyboardFreezeSource(_ source: KeyboardFreezeSource) -> some View {
    background(KeyboardFreezeSourceReader(source: source))
  }
}
