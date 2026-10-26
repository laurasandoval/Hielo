import SwiftUI

extension View {
  /// Sets the animation for Hielo popovers within this view.
  ///
  /// Apply this modifier after `hieloPopover` or to an ancestor. The animation
  /// controls presentation, dismissal, and the return after an incomplete drag.
  /// The default is `.spring(duration: 0.3, bounce: 0.2)`.
  ///
  /// ```swift
  /// Button("Show menu") { isPresented = true }
  ///     .hieloPopover(isPresented: $isPresented) { Text("Menu") }
  ///     .hieloPopoverAnimation(.spring(duration: 0.4, bounce: 0.2))
  /// ```
  ///
  /// The animation is captured when presentation starts. Reduce Motion disables
  /// these transitions. Use an animation that finishes; repeating forever prevents
  /// dismissal from reaching its cleanup completion.
  ///
  /// - Parameter animation: A SwiftUI animation, or `nil` to disable animation.
  /// - Returns: A view that supplies the animation to its Hielo popovers.
  public func hieloPopoverAnimation(_ animation: Animation?) -> some View {
    environment(\.hieloPopoverAnimation, animation)
  }
}

extension EnvironmentValues {
    @Entry var hieloPopoverAnimation: Animation? = .spring(duration: 0.3, bounce: 0.2)
}
