import SwiftUI

extension View {
  /// Provides a keyboard-freeze session to this view and its descendants.
  ///
  /// Apply this modifier to the page that contains your popover sources.
  /// For keyboard pinning, apply it to the full page that moves with the snapshot.
  /// The nearest ancestor with this modifier supplies the session to a popover.
  ///
  /// ```swift
  /// DemoView()
  ///     .keyboardFreeze(session)
  /// ```
  ///
  /// - Parameters:
  ///   - keyboardFreeze: The session that manages the page’s presentations.
  ///   - lifecycle: The cleanup policy when this view disappears. The default
  ///     cancels the session. Use `.manual` when you manage cleanup yourself.
  /// - Returns: A view that hosts the session and makes it available to descendants.
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
  let keyboardFreeze: KeyboardFreeze
  let lifecycle: KeyboardFreezeHostLifecycle

  func body(content: Content) -> some View {
    content
      .environment(\.keyboardFreezeSession, keyboardFreeze)
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

  private struct InteractionShieldButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
      Color.clear
        .contentShape(.rect)
    }
  }
}
