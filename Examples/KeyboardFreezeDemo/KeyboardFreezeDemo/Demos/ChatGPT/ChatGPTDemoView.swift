import KeyboardFreeze
import SwiftUI

struct ChatGPTDemoView: View {
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

        DemoComposer(text: $text, focus: $inputIsFocused, textLeadingPadding: 0, inputAccessory: {
          DemoComposerButton {
            isMenuPresented = true
          }
          .keyboardPopover(
            isPresented: $isMenuPresented,
            attachmentAnchor: .leading,
            popoverShape: .rect(cornerRadius: 45)
          ) {
            ChatGPTDemoMenu {
              isMenuPresented = false
            }
          }
          .keyboardPopoverStyle(.plain)
        })
        .padding(inputIsFocused ? 16 : 38)
        .animation(.smooth(duration: 0.2), value: inputIsFocused)
      }
    }
    .ignoresSafeArea(.container, edges: .bottom)
    .navigationTitle("ChatGPT")
    .navigationBarTitleDisplayMode(.inline)
    .keyboardFreeze()
  }
}

#Preview {
  NavigationStack { ChatGPTDemoView() }
}
