import SwiftUI

struct SidebarComposer: View {
  @Binding var message: String
  let inputIsFocused: FocusState<Bool>.Binding

  var body: some View {
    TextField("Message", text: $message, axis: .vertical)
      .focused(inputIsFocused)
      .lineLimit(1)
      .padding(.horizontal, 16)
      .frame(maxWidth: .infinity, minHeight: 48, maxHeight: 48)
      .glassEffect(.regular.interactive(), in: .capsule)
  }
}
