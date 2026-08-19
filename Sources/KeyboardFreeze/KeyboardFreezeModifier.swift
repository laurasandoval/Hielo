import SwiftUI

extension View {
  /// Installs the app-side half of a keyboard freeze session.
  ///
  /// Apply this modifier to the full-screen page that should move with a pinned
  /// keyboard, rather than to the text field or another nested control.
  public func keyboardFreeze(
    _ keyboardFreeze: KeyboardFreeze,
    lifecycle: KeyboardFreezeHostLifecycle = .cancelOnDisappear
  ) -> some View {
    modifier(
      KeyboardFreezeModifier(
        keyboardFreeze: keyboardFreeze,
        lifecycle: lifecycle
      )
    )
  }
}

private struct KeyboardFreezeModifier: ViewModifier {
  @Bindable var keyboardFreeze: KeyboardFreeze
  let lifecycle: KeyboardFreezeHostLifecycle

  func body(content: Content) -> some View {
    content
      .overlay {
        if keyboardFreeze.isPresentingOverlay {
          Button("Dismiss keyboard overlay", action: handleOutsideOverlayTap)
            .buttonStyle(InteractionShieldButtonStyle())
            .ignoresSafeArea()
            .accessibilityHidden(true)
        }
      }
      .overlay(alignment: .bottom) {
        if keyboardFreeze.isPinned, keyboardFreeze.pinnedKeyboardHeight > 0 {
          KeyboardFreezePinnedKeyboard(keyboardFreeze: keyboardFreeze)
            .frame(height: keyboardFreeze.pinnedKeyboardHeight)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
        }
      }
      .onDisappear(perform: handleDisappear)
  }

  private func handleOutsideOverlayTap() {
    keyboardFreeze.handleOutsideOverlayTap()
  }

  private func handleDisappear() {
    guard lifecycle == .cancelOnDisappear else { return }
    keyboardFreeze.cancel()
  }
}

private struct InteractionShieldButtonStyle: ButtonStyle {
  func makeBody(configuration: Configuration) -> some View {
    Color.clear
      .contentShape(.rect)
  }
}
