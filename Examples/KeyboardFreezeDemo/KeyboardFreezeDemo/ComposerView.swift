import KeyboardFreeze
import SwiftUI

struct ComposerView: View {
  @Binding var text: String
  @Binding var isMenuPresented: Bool
  let inputIsFocused: FocusState<Bool>.Binding
  let openMenu: () -> Void

  var body: some View {
    GlassEffectContainer(spacing: 12) {
      HStack(spacing: 12) {
        Button("Open menu", systemImage: "plus", action: openMenu)
          .labelStyle(.iconOnly)
          .font(.title3)
          .frame(width: 48, height: 48)
          .contentShape(.circle)
          .buttonStyle(.plain)
          .keyboardPopover(
            isPresented: $isMenuPresented,
            attachmentAnchor: .leading
          ) {
            Text("Hello World")
              .font(.headline)
              .frame(width: 250, height: 250)
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
    isMenuPresented: .constant(false),
    inputIsFocused: $inputIsFocused,
    openMenu: {}
  )
  .padding()
}
