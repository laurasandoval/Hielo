import SwiftUI

struct StyledHieloPopover<Source: View, Content: View>: View {
  @Binding var isPresented: Bool
  let attachmentAnchor: UnitPoint
  let sourceShape: HieloPopoverShape
  let popoverShape: HieloPopoverShape
  let source: Source
  let content: Content

  @Environment(\.hieloPopoverStyle) private var style

  var body: some View {
    HieloPopover(
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
