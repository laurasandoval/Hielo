import SwiftUI

extension View {
  /// Associates this view with a source for overlay positioning.
  ///
  /// Use this modifier when presenting an overlay directly through a
  /// ``HieloSession`` session. It tracks the view’s screen position so you
  /// can pass the source to the session without calculating coordinates.
  ///
  /// - Parameter source: The source that tracks this view. Use a separate source
  ///   for each view you want to track.
  /// - Returns: A view that updates the source as its geometry changes.
  public func hieloSource(_ source: HieloSource) -> some View {
    background(HieloSourceReader(source: source))
  }
}
