import KeyboardFreeze
import SwiftUI

struct ChatComposer: View {
  @Binding var message: String
  let inputIsFocused: FocusState<Bool>.Binding
  let attachmentSource: KeyboardFreezeSource
  let openAttachments: () -> Void

  var body: some View {
    GlassEffectContainer(spacing: 12) {
      HStack(spacing: 12) {
        Button(
          "Open attachments",
          systemImage: "plus",
          action: openAttachments
        )
        .labelStyle(.iconOnly)
        .font(.title3)
        .frame(width: 48, height: 48)
        .contentShape(.circle)
        .buttonStyle(.plain)
        .glassEffect(.regular.interactive(), in: .circle)
        .keyboardFreezeSource(attachmentSource)

        TextField("Message", text: $message, axis: .vertical)
          .focused(inputIsFocused)
          .lineLimit(1)
          .padding(.horizontal, 16)
          .frame(maxWidth: .infinity, minHeight: 48, maxHeight: 48)
          .glassEffect(.regular.interactive(), in: .capsule)
      }
    }
  }
}
