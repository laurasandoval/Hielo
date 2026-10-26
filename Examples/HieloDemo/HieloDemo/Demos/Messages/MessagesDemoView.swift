import Hielo
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
          .hieloPopover(
            isPresented: $isMenuPresented,
            attachmentAnchor: .leading
          ) {
            MessagesDemoMenu {
              isMenuPresented = false
            }
          }
          .hieloPopoverStyle(.glass)
        })
        .padding(inputIsFocused ? 16 : 28)
        .animation(.smooth(duration: 0.2), value: inputIsFocused)
      }
    }
    .ignoresSafeArea(.container, edges: .bottom)
    .navigationTitle("Messages")
    .navigationBarTitleDisplayMode(.inline)
    .hieloHost()
  }
}

#Preview {
  NavigationStack { MessagesDemoView() }
}
