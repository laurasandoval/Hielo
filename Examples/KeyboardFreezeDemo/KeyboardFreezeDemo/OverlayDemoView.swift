import Combine
import KeyboardFreeze
import SwiftUI
import UIKit

struct OverlayDemoView: View {
  private enum Menu {
    case glass
    case plain
  }

  @State private var keyboardFreeze = KeyboardFreeze()
  @State private var text = ""
  @State private var isMenuPresented = false
  @State private var isPlainMenuPresented = false
  @State private var pendingMenu: Menu?
  @State private var keyboardIsVisible = false
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
          inputIsFocused: $inputIsFocused,
          openMenu: { requestMenu(.glass) },
          openPlainMenu: { requestMenu(.plain) }
        )
        .padding(composerSpacing)
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
    inputIsFocused ? 16 : 28
  }

  private func requestMenu(_ menu: Menu) {
    guard keyboardIsVisible else {
      pendingMenu = menu
      inputIsFocused = true
      return
    }
    present(menu)
  }

  private func handleKeyboardDidShow(_: Notification) {
    keyboardIsVisible = true
    guard let pendingMenu else { return }
    self.pendingMenu = nil
    present(pendingMenu)
  }

  private func handleKeyboardDidHide(_: Notification) {
    keyboardIsVisible = false
  }

  private func present(_ menu: Menu) {
    switch menu {
    case .glass:
      isMenuPresented = true
    case .plain:
      isPlainMenuPresented = true
    }
  }
}

#Preview {
  OverlayDemoView()
}
