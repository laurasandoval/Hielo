import Combine
import KeyboardFreeze
import SwiftUI
import UIKit

struct OverlayDemoView: View {
  @State private var keyboardFreeze = KeyboardFreeze()
  @State private var text = ""
  @State private var isMenuPresented = false
  @State private var isWaitingForKeyboard = false
  @State private var keyboardIsVisible = false
  @FocusState private var inputIsFocused: Bool

  var body: some View {
    ZStack {
      Rectangle()
        .fill(.background)
        .ignoresSafeArea()

      VStack {
        Spacer()

        ComposerView(
          text: $text,
          isMenuPresented: $isMenuPresented,
          inputIsFocused: $inputIsFocused,
          openMenu: requestMenu
        )
        .padding(.horizontal, composerSpacing)
        .padding(.bottom, composerSpacing)
        .animation(
          .smooth(duration: 0.2),
          value: inputIsFocused
        )
      }
    }
    .ignoresSafeArea(.container, edges: .bottom)
    .keyboardFreeze(keyboardFreeze)
    .onReceive(
      NotificationCenter.default.publisher(
        for: UIResponder.keyboardDidShowNotification
      ),
      perform: handleKeyboardDidShow
    )
    .onReceive(
      NotificationCenter.default.publisher(
        for: UIResponder.keyboardDidHideNotification
      ),
      perform: handleKeyboardDidHide
    )
  }

  private var composerSpacing: CGFloat {
    inputIsFocused ? 12 : 28
  }

  private func requestMenu() {
    guard keyboardIsVisible else {
      isWaitingForKeyboard = true
      inputIsFocused = true
      return
    }
    presentMenu()
  }

  private func handleKeyboardDidShow(_: Notification) {
    keyboardIsVisible = true
    guard isWaitingForKeyboard else { return }
    isWaitingForKeyboard = false
    presentMenu()
  }

  private func handleKeyboardDidHide(_: Notification) {
    keyboardIsVisible = false
  }

  private func presentMenu() {
    isMenuPresented = true
  }
}

#Preview {
  OverlayDemoView()
}
