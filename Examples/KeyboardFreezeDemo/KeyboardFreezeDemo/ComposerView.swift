import KeyboardFreeze
import SwiftUI

struct ComposerView: View {
  @Binding var text: String
  @Binding var isMenuPresented: Bool
  @Binding var isPlainMenuPresented: Bool
  let inputIsFocused: FocusState<Bool>.Binding

  var body: some View {
    GlassEffectContainer(spacing: 12) {
      HStack(spacing: 12) {
        Button("Open menu", systemImage: "plus") {
          isMenuPresented = true
        }
        .labelStyle(.iconOnly)
        .font(.title3)
        .frame(width: 48, height: 48)
        .contentShape(.circle)
        .buttonStyle(.plain)
        .keyboardPopover(
          isPresented: $isMenuPresented,
          attachmentAnchor: .leading,
          sourceShape: .capsule,
          popoverShape: .rect(cornerRadius: 32)
        ) {
          Text("Hello World")
            .font(.headline)
            .frame(width: 250, height: 250)
        }

        HStack(spacing: 8) {
          TextField("Message", text: $text)
            .focused(inputIsFocused)
            .padding(.leading, 16)

          Button(
            "Open plain menu",
            systemImage: "paperclip"
          ) {
            isPlainMenuPresented = true
          }
          .labelStyle(.iconOnly)
          .foregroundStyle(.primary)
          .frame(width: 44, height: 44)
          .contentShape(.circle)
          .buttonStyle(.plain)
          .keyboardPopover(
            isPresented: $isPlainMenuPresented,
            attachmentAnchor: .trailing,
            sourceGlass: nil,
            sourceShape: .circle,
            popoverShape: .rect(cornerRadius: 32)
          ) {
            Text("Plain button")
              .font(.headline)
              .frame(width: 250, height: 250)
          }
        }
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
    isPlainMenuPresented: .constant(false),
    inputIsFocused: $inputIsFocused
  )
  .padding()
}
