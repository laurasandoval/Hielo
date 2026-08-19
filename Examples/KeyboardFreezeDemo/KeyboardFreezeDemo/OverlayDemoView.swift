import Combine
import KeyboardFreeze
import SwiftUI
import UIKit

struct OverlayDemoView: View {
  @State private var keyboardFreeze = KeyboardFreeze()
  @State private var menuSource = KeyboardFreezeSource()
  @State private var text = ""
  @State private var isMenuPresented = false
  @State private var isWaitingForKeyboard = false
  @State private var keyboardIsVisible = false
  @State private var showsUnavailableAlert = false
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
          inputIsFocused: $inputIsFocused,
          menuSource: menuSource,
          isMenuPresented: isMenuPresented,
          openMenu: requestMenu
        )
        .padding(.horizontal, composerSpacing)
        .padding(.bottom, composerSpacing)
        .animation(.smooth, value: inputIsFocused)
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
    .onChange(of: isMenuPresented, handleMenuPresentationChange)
    .alert("Keyboard unavailable", isPresented: $showsUnavailableAlert) {
      Button("OK", role: .cancel) {}
    } message: {
      Text("Try again with the software keyboard visible.")
    }
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
    guard let sourceFrame = menuSource.frameInScreen else {
      showsUnavailableAlert = true
      return
    }
    let result = keyboardFreeze.presentOverlay(
      from: menuSource,
      overlayFrame: { $0.sourceFrame },
      onOutsideTap: { isMenuPresented = false },
      content: { _ in
        KeyboardPopoverPresenter(
          isPresented: $isMenuPresented,
          sourceFrame: sourceFrame
        )
      }
    )

    if result.succeeded {
      Task { @MainActor in
        await Task.yield()
        isMenuPresented = true
      }
    } else {
      showsUnavailableAlert = true
    }
  }

  private func handleMenuPresentationChange(
    _: Bool,
    _ isPresented: Bool
  ) {
    guard !isPresented else { return }
    keyboardFreeze.dismissOverlay(after: .milliseconds(400))
  }
}

#Preview {
  OverlayDemoView()
}
