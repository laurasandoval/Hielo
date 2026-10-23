import KeyboardFreeze
import SwiftUI

struct MessagesDemoView: View {
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
            attachmentAnchor: .leading
          ) {
            MessagesDemoMenu {
              isMenuPresented = false
            }
          }
          .keyboardPopoverStyle(.glass)
        })
        .padding(inputIsFocused ? 16 : 28)
        .animation(.smooth(duration: 0.2), value: inputIsFocused)
      }
    }
    .ignoresSafeArea(.container, edges: .bottom)
    .navigationTitle("Messages")
    .navigationBarTitleDisplayMode(.inline)
    .keyboardFreeze()
  }
}

#Preview {
  NavigationStack { MessagesDemoView() }
}
