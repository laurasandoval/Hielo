import SwiftUI

struct StyledKeyboardPopover<Source: View, Content: View>: View {
  @Binding var isPresented: Bool
  let attachmentAnchor: UnitPoint
  let sourceShape: KeyboardPopoverShape
  let popoverShape: KeyboardPopoverShape
  let source: Source
  let content: Content

  @Environment(\.keyboardPopoverStyle) private var style

  var body: some View {
    KeyboardPopover(
      isPresented: $isPresented,
      attachmentAnchor: attachmentAnchor,
      sourceGlass: style == .glass ? .regular.interactive() : nil,
      sourceShape: sourceShape,
      popoverShape: popoverShape,
      source: { source },
      content: { content }
    )
  }
}
