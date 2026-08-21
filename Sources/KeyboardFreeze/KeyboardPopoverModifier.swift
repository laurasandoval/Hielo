import SwiftUI

extension View {
  /// Expands this view into custom content over a frozen keyboard or app.
  ///
  /// Apply ``View/keyboardFreeze(_:lifecycle:)`` to an ancestor. The popover
  /// content controls its own size with standard SwiftUI layout modifiers.
  /// By default, the source uses interactive Liquid Glass in a capsule and the
  /// popover uses a continuously rounded rectangle. Centered attachment-axis
  /// components adapt toward the nearest app-window edge when no keyboard is
  /// visible.
  public func keyboardPopover<PopoverContent: View>(
    isPresented: Binding<Bool>,
    attachmentAnchor: UnitPoint = .leading,
    sourceGlass: Glass? = .regular.interactive(),
    sourceShape: KeyboardPopoverShape = .capsule,
    popoverShape: KeyboardPopoverShape = .rect(cornerRadius: 32),
    @ViewBuilder content: () -> PopoverContent
  ) -> some View {
    KeyboardPopover(
      isPresented: isPresented,
      attachmentAnchor: attachmentAnchor,
      sourceGlass: sourceGlass,
      sourceShape: sourceShape,
      popoverShape: popoverShape,
      source: { self },
      content: content
    )
  }
}
