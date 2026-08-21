import KeyboardFreeze
import SwiftUI

struct OverlayDemoView: View {
  @State private var keyboardFreeze = KeyboardFreeze()
  @State private var text = ""
  @State private var isMenuPresented = false
  @State private var isPlainMenuPresented = false
  @FocusState private var inputIsFocused: Bool

  var body: some View {
    ZStack {
      Rectangle()
        .fill(.background)
        .ignoresSafeArea()

      ScrollView {
        Color.clear
          .frame(height: 1)
      }
      .contentShape(.rect)
      .onTapGesture {
        inputIsFocused = false
      }
      .scrollDismissesKeyboard(.interactively)

      VStack {
        Spacer()

        ComposerView(
          text: $text,
          isMenuPresented: $isMenuPresented,
          isPlainMenuPresented: $isPlainMenuPresented,
          inputIsFocused: $inputIsFocused
        )
        .padding(inputIsFocused ? 16 : 28)
        .animation(
          .smooth(duration: 0.2),
          value: inputIsFocused
        )
      }
    }
    .ignoresSafeArea(.container, edges: .bottom)
    .keyboardFreeze(keyboardFreeze)
  }
}

#Preview {
  OverlayDemoView()
}
