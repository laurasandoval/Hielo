import SwiftUI

/// Demo styling only; each screen supplies its own buttons and package modifiers.
struct DemoComposer<Accessory: View, InputAccessory: View>: View {
  @Binding private var text: String
  private let focus: FocusState<Bool>.Binding
  private let textLeadingPadding: CGFloat
  private let height: CGFloat
  private let spacing: CGFloat
  private let accessory: Accessory
  private let inputAccessory: InputAccessory

  init(
    text: Binding<String>,
    focus: FocusState<Bool>.Binding,
    textLeadingPadding: CGFloat = 16,
    height: CGFloat = 48,
    spacing: CGFloat = 12,
    @ViewBuilder accessory: () -> Accessory = { EmptyView() },
    @ViewBuilder inputAccessory: () -> InputAccessory = { EmptyView() }
  ) {
    _text = text
    self.focus = focus
    self.textLeadingPadding = textLeadingPadding
    self.height = height
    self.spacing = spacing
    self.accessory = accessory()
    self.inputAccessory = inputAccessory()
  }

  var body: some View {
    GlassEffectContainer(spacing: spacing) {
      HStack(spacing: spacing) {
        accessory

        HStack(spacing: 0) {
          inputAccessory
          TextField("Message", text: $text)
            .focused(focus)
            .padding(.leading, textLeadingPadding)
            .padding(.trailing, 16)
        }
        .frame(maxWidth: .infinity)
        .frame(height: height)
        .glassEffect(.regular.interactive(), in: .capsule)
      }
    }
  }
}
