import SwiftUI

extension View {
  /// Provides an automatically managed keyboard-freeze session to this page.
  ///
  /// Apply this modifier to the page containing your popover sources. The
  /// session remains stable across view updates and cancels its presentation
  /// when the page disappears. Use `hieloHost(_:lifecycle:)` instead
  /// when you need direct access for keyboard pinning or restoration.
  ///
  /// - Returns: A view that owns and hosts a keyboard-freeze session.
  public func hieloHost() -> some View {
    modifier(HieloAutomaticHostModifier())
  }

  /// Provides a keyboard-freeze session to this view and its descendants.
  ///
  /// Apply this modifier to the page that contains your popover sources.
  /// For keyboard pinning, apply it to the full page that moves with the snapshot.
  /// The nearest ancestor with this modifier supplies the session to a popover.
  ///
  /// ```swift
  /// DemoView()
  ///     .hieloHost(session)
  /// ```
  ///
  /// - Parameters:
  ///   - session: The session that manages the page’s presentations.
  ///   - lifecycle: The cleanup policy when this view disappears. The default
  ///     cancels the session. Use `.manual` when you manage cleanup yourself.
  /// - Returns: A view that hosts the session and makes it available to descendants.
  public func hieloHost(
    _ session: HieloSession,
    lifecycle: HieloHostLifecycle = .cancelOnDisappear
  ) -> some View {
    modifier(
      HieloHostModifier(
        session: session,
        lifecycle: lifecycle
      )
    )
  }
}

private struct HieloHostModifier: ViewModifier {
  let session: HieloSession
  let lifecycle: HieloHostLifecycle

  func body(content: Content) -> some View {
    content
      .environment(\.hieloSession, session)
      .overlay {
        if session.isPresentingOverlay {
          Button("Dismiss keyboard overlay", action: handleOutsideOverlayTap)
            .buttonStyle(InteractionShieldButtonStyle())
            .ignoresSafeArea()
            .accessibilityHidden(true)
        }
      }
      .overlay(alignment: .bottom) {
        if session.isPinned, session.pinnedKeyboardHeight > 0 {
          HieloPinnedKeyboard(session: session)
            .frame(height: session.pinnedKeyboardHeight)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
        }
      }
      .onDisappear(perform: handleDisappear)
  }

  private func handleOutsideOverlayTap() {
    session.handleOutsideOverlayTap()
  }

  private func handleDisappear() {
    guard lifecycle == .cancelOnDisappear else { return }
    session.cancel()
  }

  private struct InteractionShieldButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
      Color.clear
        .contentShape(.rect)
    }
  }
}
