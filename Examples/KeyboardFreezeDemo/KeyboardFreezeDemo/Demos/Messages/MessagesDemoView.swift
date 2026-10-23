import KeyboardFreeze
import SwiftUI

struct MessagesDemoView: View {
  @State private var session = KeyboardFreeze()
  @State private var text = ""
  @State private var isMenuPresented = false
  @FocusState private var inputIsFocused: Bool

  var body: some View {
    ZStack {
      Rectangle()
        .fill(.background)
        .ignoresSafeArea()

      ScrollView {
        Color.clear.frame(height: 1)
      }
      .contentShape(.rect)
      .onTapGesture { inputIsFocused = false }
      .scrollDismissesKeyboard(.interactively)

      VStack {
        Spacer()

        DemoComposer(text: $text, focus: $inputIsFocused, accessory: {
          DemoComposerButton {
            isMenuPresented = true
          }
          .keyboardPopover(
            isPresented: $isMenuPresented,
            attachmentAnchor: .leading,
            sourceGlass: .regular.interactive()
          ) {
            MessagesDemoMenu {
              isMenuPresented = false
            }
          }
        })
        .padding(inputIsFocused ? 16 : 28)
        .animation(.smooth(duration: 0.2), value: inputIsFocused)
      }
    }
    .ignoresSafeArea(.container, edges: .bottom)
    .navigationTitle("Messages")
    .navigationBarTitleDisplayMode(.inline)
    .keyboardFreeze(session)
  }
}

#Preview {
  NavigationStack { MessagesDemoView() }
}
