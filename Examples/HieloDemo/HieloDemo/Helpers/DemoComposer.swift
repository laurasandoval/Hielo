import SwiftUI

/// Demo styling only; each screen supplies its own buttons and package modifiers.
struct DemoComposer<Accessory: View>: View {
  @Binding private var text: String
  private let focus: FocusState<Bool>.Binding
  private let accessory: Accessory

  init(
    text: Binding<String>,
    focus: FocusState<Bool>.Binding,
    @ViewBuilder accessory: () -> Accessory
  ) {
    _text = text
    self.focus = focus
    self.accessory = accessory()
  }

  var body: some View {
    GlassEffectContainer(spacing: 10) {
      HStack(spacing: 10) {
        accessory

        TextField("Message", text: $text)
          .focused(focus)
          .padding(.horizontal, 16)
          .frame(maxWidth: .infinity)
          .frame(height: 42)
          .glassEffect(.regular.interactive(), in: .capsule)
      }
    }
  }
}
