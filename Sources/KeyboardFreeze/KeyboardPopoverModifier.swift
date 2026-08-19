import SwiftUI

extension View {
  /// Expands this view into custom content over a frozen keyboard.
  ///
  /// Apply ``View/keyboardFreeze(_:lifecycle:)`` to an ancestor. The popover
  /// content controls its own size with standard SwiftUI layout modifiers.
  public func keyboardPopover<PopoverContent: View>(
    isPresented: Binding<Bool>,
    attachmentAnchor: UnitPoint = .leading,
    @ViewBuilder content: () -> PopoverContent
  ) -> some View {
    KeyboardPopover(
      isPresented: isPresented,
      attachmentAnchor: attachmentAnchor,
      source: { self },
      content: content
    )
  }
}
