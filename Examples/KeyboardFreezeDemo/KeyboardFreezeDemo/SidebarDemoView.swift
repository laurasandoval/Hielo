import KeyboardFreeze
import SwiftUI

struct SidebarDemoView: View {
  private let sidebarWidth: CGFloat = 300

  @State private var keyboardFreeze = KeyboardFreeze()
  @State private var message = ""
  @State private var pageOffset: CGFloat = 0
  @State private var dragOrigin: CGFloat = 0
  @State private var isDragging = false
  @State private var shouldRestoreFocus = false
  @FocusState private var inputIsFocused: Bool

  var body: some View {
    ZStack(alignment: .leading) {
      SidebarPanel(close: closeSidebar)

      SidebarChatPage(
        message: $message,
        inputIsFocused: $inputIsFocused,
        openSidebar: openSidebar
      )
      .keyboardFreeze(keyboardFreeze)
      .offset(x: pageOffset)
      .simultaneousGesture(sidebarDragGesture)
    }
    .navigationTitle("Pinned keyboard")
    .navigationBarTitleDisplayMode(.inline)
  }

  private var sidebarDragGesture: some Gesture {
    DragGesture(minimumDistance: 8)
      .onChanged(handleDragChanged)
      .onEnded(handleDragEnded)
  }

  private func handleDragChanged(_ value: DragGesture.Value) {
    if !isDragging {
      isDragging = true
      dragOrigin = pageOffset
      if pageOffset == 0 {
        prepareKeyboardForMovement()
      }
    }

    pageOffset = min(
      max(dragOrigin + value.translation.width, 0),
      sidebarWidth
    )
  }

  private func handleDragEnded(_: DragGesture.Value) {
    isDragging = false
    settleSidebar(open: pageOffset > sidebarWidth / 2)
  }

  private func openSidebar() {
    guard pageOffset == 0 else { return }
    prepareKeyboardForMovement()
    Task { @MainActor in
      await Task.yield()
      withAnimation(.smooth) {
        pageOffset = sidebarWidth
      }
    }
  }

  private func closeSidebar() {
    settleSidebar(open: false)
  }

  private func prepareKeyboardForMovement() {
    shouldRestoreFocus = inputIsFocused
    _ = keyboardFreeze.pinKeyboard {
      inputIsFocused = false
    }
  }

  private func settleSidebar(open: Bool) {
    withAnimation(.smooth) {
      pageOffset = open ? sidebarWidth : 0
    } completion: {
      guard !open, shouldRestoreFocus else { return }
      shouldRestoreFocus = false

      if keyboardFreeze.isPinned {
        keyboardFreeze.restoreKeyboard {
          inputIsFocused = true
        }
      } else {
        inputIsFocused = true
      }
    }
  }
}

#Preview {
  NavigationStack {
    SidebarDemoView()
  }
}
