import SwiftUI

struct KeyboardFreezeAutomaticHostModifier: ViewModifier {
  @State private var session = KeyboardFreeze()

  func body(content: Content) -> some View {
    content.keyboardFreeze(session)
  }
}
