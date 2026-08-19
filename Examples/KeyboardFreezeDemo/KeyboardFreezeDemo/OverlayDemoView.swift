import Combine
import KeyboardFreeze
import SwiftUI
import UIKit

struct OverlayDemoView: View {
  @State private var keyboardFreeze = KeyboardFreeze()
  @State private var attachmentSource = KeyboardFreezeSource()
  @State private var message = ""
  @State private var isWaitingForKeyboard = false
  @State private var showsUnavailableAlert = false
  @FocusState private var inputIsFocused: Bool

  var body: some View {
    ZStack {
      LinearGradient(
        colors: [.blue.opacity(0.08), .clear],
        startPoint: .top,
        endPoint: .bottom
      )
      .ignoresSafeArea()

      ConversationView()

      VStack {
        Spacer()

        ChatComposer(
          message: $message,
          inputIsFocused: $inputIsFocused,
          attachmentSource: attachmentSource,
          openAttachments: requestAttachmentOverlay
        )
        .padding(.horizontal, composerSpacing)
        .padding(.bottom, composerSpacing)
        .animation(.smooth, value: inputIsFocused)
      }
    }
    .ignoresSafeArea(.container, edges: .bottom)
    .keyboardFreeze(keyboardFreeze)
    .navigationTitle("Overlay")
    .navigationBarTitleDisplayMode(.inline)
    .onReceive(
      NotificationCenter.default.publisher(
        for: UIResponder.keyboardDidShowNotification
      ),
      perform: handleKeyboardDidShow
    )
    .alert("Keyboard unavailable", isPresented: $showsUnavailableAlert) {
      Button("OK", role: .cancel) {}
    } message: {
      Text("Try again with the software keyboard visible.")
    }
  }

  private var composerSpacing: CGFloat {
    inputIsFocused ? 12 : 28
  }

  private func requestAttachmentOverlay() {
    guard inputIsFocused else {
      isWaitingForKeyboard = true
      inputIsFocused = true
      return
    }
    presentAttachmentOverlay()
  }

  private func handleKeyboardDidShow(_: Notification) {
    guard isWaitingForKeyboard else { return }
    isWaitingForKeyboard = false
    presentAttachmentOverlay()
  }

  private func presentAttachmentOverlay() {
    let result = keyboardFreeze.presentOverlay(
      from: attachmentSource,
      overlayFrame: attachmentOverlayFrame
    ) { _ in
      AttachmentOverlay(dismiss: dismissAttachmentOverlay)
    }

    if !result.succeeded {
      showsUnavailableAlert = true
    }
  }

  private func attachmentOverlayFrame(
    _ context: KeyboardFreeze.Context
  ) -> CGRect {
    let size = CGSize(width: 250, height: 250)
    let minimumMargin: CGFloat = 12
    let maximumX = context.windowBounds.maxX - size.width - minimumMargin
    let x = min(max(context.sourceFrame.minX, minimumMargin), maximumX)
    let y = max(
      context.windowBounds.minY + minimumMargin,
      context.keyboardFrame.minY - size.height - minimumMargin
    )
    return CGRect(origin: CGPoint(x: x, y: y), size: size)
  }

  private func dismissAttachmentOverlay() {
    keyboardFreeze.dismissOverlay()
  }
}

#Preview {
  NavigationStack {
    OverlayDemoView()
  }
}
