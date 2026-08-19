import SwiftUI

struct SidebarChatPage: View {
  @Binding var message: String
  let inputIsFocused: FocusState<Bool>.Binding
  let openSidebar: () -> Void

  var body: some View {
    ZStack {
      Color(uiColor: .systemBackground)
        .ignoresSafeArea()

      VStack(spacing: 0) {
        HStack {
          Button("Open sidebar", systemImage: "sidebar.left", action: openSidebar)
            .labelStyle(.iconOnly)
            .buttonStyle(.glass)
            .buttonBorderShape(.circle)

          Text("Moving page")
            .font(.headline)

          Spacer()
        }
        .padding()

        ConversationView()

        SidebarComposer(
          message: $message,
          inputIsFocused: inputIsFocused
        )
        .padding(.horizontal, inputIsFocused.wrappedValue ? 12 : 28)
        .padding(.bottom, inputIsFocused.wrappedValue ? 12 : 28)
        .animation(.smooth, value: inputIsFocused.wrappedValue)
      }
    }
    .ignoresSafeArea(.container, edges: .bottom)
    .shadow(color: .black.opacity(0.16), radius: 18, x: -4)
  }
}
