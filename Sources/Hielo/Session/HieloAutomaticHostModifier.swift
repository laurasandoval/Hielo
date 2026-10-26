import SwiftUI

struct HieloAutomaticHostModifier: ViewModifier {
  @State private var session = HieloSession()

  func body(content: Content) -> some View {
    content.hieloHost(session)
  }
}
