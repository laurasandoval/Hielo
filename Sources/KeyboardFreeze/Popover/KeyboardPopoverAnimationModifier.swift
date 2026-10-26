import SwiftUI

extension View {
  /// Sets the animation for keyboard popovers within this view.
  ///
  /// Apply this modifier after `keyboardPopover` or to an ancestor. The animation
  /// controls presentation, dismissal, and the return after an incomplete drag.
  /// The default is `.spring(duration: 0.3, bounce: 0.2)`.
  ///
  /// ```swift
  /// Button("Show menu") { isPresented = true }
  ///     .keyboardPopover(isPresented: $isPresented) { Text("Menu") }
  ///     .keyboardPopoverAnimation(.spring(duration: 0.4, bounce: 0.2))
  /// ```
  ///
  /// The animation is captured when presentation starts. Reduce Motion disables
  /// these transitions. Use an animation that finishes; repeating forever prevents
  /// dismissal from reaching its cleanup completion.
  ///
  /// - Parameter animation: A SwiftUI animation, or `nil` to disable animation.
  /// - Returns: A view that supplies the animation to its keyboard popovers.
  public func keyboardPopoverAnimation(_ animation: Animation?) -> some View {
    environment(\.keyboardPopoverAnimation, animation)
  }
}

extension EnvironmentValues {
    @Entry var keyboardPopoverAnimation: Animation? = .spring(duration: 0.3, bounce: 0.2)
}
