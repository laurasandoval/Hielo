import SwiftUI

extension View {
  /// Provides a presentation host for Hielo popovers on this page.
  ///
  /// Apply this modifier to the page containing your popover sources. It owns
  /// the presentation session and dismisses active content when the page disappears.
  ///
  /// - Returns: A view that hosts Hielo popovers.
  public func hieloHost() -> some View {
    modifier(HieloAutomaticHostModifier())
  }

  func hieloHost(_ session: HieloSession) -> some View {
    modifier(HieloHostModifier(session: session))
  }
}

private struct HieloHostModifier: ViewModifier {
  let session: HieloSession

  func body(content: Content) -> some View {
    content
      .environment(\.hieloSession, session)
      .overlay {
        if session.isPresentingOverlay {
          Button("Dismiss popover", action: session.handleOutsideOverlayTap)
            .buttonStyle(InteractionShieldButtonStyle())
            .ignoresSafeArea()
            .accessibilityHidden(true)
        }
      }
      .onDisappear(perform: session.cancel)
  }

  private struct InteractionShieldButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
      Color.clear
        .contentShape(.rect)
    }
  }
}
