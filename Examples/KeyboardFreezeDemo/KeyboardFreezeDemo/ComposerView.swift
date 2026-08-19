import KeyboardFreeze
import SwiftUI

struct ComposerView: View {
  @Binding var text: String
  let inputIsFocused: FocusState<Bool>.Binding
  let menuSource: KeyboardFreezeSource
  let isMenuPresented: Bool
  let openMenu: () -> Void

  var body: some View {
    GlassEffectContainer(spacing: 12) {
      HStack(spacing: 12) {
        if isMenuPresented {
          Color.clear
            .frame(width: 48, height: 48)
        } else {
          Button("Open menu", systemImage: "plus", action: openMenu)
            .labelStyle(.iconOnly)
            .font(.title3)
            .frame(width: 48, height: 48)
            .contentShape(.circle)
            .buttonStyle(.plain)
            .glassEffect(.regular.interactive(), in: .circle)
            .keyboardFreezeSource(menuSource)
        }

        TextField("Text", text: $text, axis: .vertical)
          .focused(inputIsFocused)
          .lineLimit(1)
          .padding(.horizontal, 16)
          .frame(maxWidth: .infinity, minHeight: 48, maxHeight: 48)
          .glassEffect(.regular.interactive(), in: .capsule)
      }
    }
  }
}

#Preview {
  @Previewable @State var text = ""
  @FocusState var inputIsFocused: Bool

  ComposerView(
    text: $text,
    inputIsFocused: $inputIsFocused,
    menuSource: KeyboardFreezeSource(),
    isMenuPresented: false,
    openMenu: {}
  )
  .padding()
}
