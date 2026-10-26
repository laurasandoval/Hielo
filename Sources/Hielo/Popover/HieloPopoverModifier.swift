import SwiftUI

extension View {
  /// Presents a popover while preserving the keyboard’s appearance when a binding is true.
  ///
  /// Use this modifier to present custom content from a view, such as a button.
  /// Apply ``View/hieloHost()`` to an ancestor to provide the
  /// session that manages the presentation.
  ///
  /// The following example presents a menu from a button:
  ///
  /// ```swift
  /// struct PopoverExample: View {
  ///     @State private var isPresented = false
  ///
  ///     var body: some View {
  ///         Button("Show menu") {
  ///             isPresented = true
  ///         }
  ///         .hieloPopover(isPresented: $isPresented) {
  ///             Text("Menu content")
  ///                 .padding()
  ///         }
  ///         .hieloHost()
  ///     }
  /// }
  /// ```
  ///
  /// The content determines the popover’s size. Use standard SwiftUI layout
  /// modifiers to configure that size. When the keyboard isn’t visible, the
  /// popover appears over the app. Keep the original input focused while the
  /// popover is presented to preserve the keyboard.
  ///
  /// Content mounts once per presentation and inherits the source's environment
  /// at presentation time. Later ancestor environment changes aren't forwarded.
  /// Keep state that must survive dismissal in the parent or a model, and dismiss
  /// by setting `isPresented` to `false`.
  ///
  /// Centered attachment components adapt toward the nearest app-window edge
  /// when no keyboard is visible.
  ///
  /// The source uses the inherited ``HieloPopoverStyle``, which defaults
  /// to glass. Apply `hieloPopoverStyle(_:)` to select a plain source.
  ///
  /// - Parameters:
  ///   - isPresented: A binding that controls presentation. Dismissing the
  ///     popover sets the binding to `false`.
  ///   - attachmentAnchor: The point used to attach the popover to its source.
  ///     The default is `.leading`.
  ///   - sourceShape: The source shape. The default is a capsule.
  ///   - popoverShape: The presented shape. The default is a continuously rounded
  ///     rectangle with a corner radius of 32 points.
  ///   - content: A closure that creates the popover’s content.
  /// - Returns: A view that presents the popover when `isPresented` is `true`.
  public func hieloPopover<PopoverContent: View>(
    isPresented: Binding<Bool>,
    attachmentAnchor: UnitPoint = .leading,
    sourceShape: HieloPopoverShape = .capsule,
    popoverShape: HieloPopoverShape = .rect(cornerRadius: 32),
    @ViewBuilder content: () -> PopoverContent
  ) -> some View {
    StyledHieloPopover(
      isPresented: isPresented,
      attachmentAnchor: attachmentAnchor,
      sourceShape: sourceShape,
      popoverShape: popoverShape,
      source: self,
      content: content()
    )
  }

  /// Presents a popover while preserving the keyboard’s appearance when a binding is true.
  ///
  /// Use this modifier to present custom content from a view, such as a button.
  /// Apply ``View/hieloHost()`` to an ancestor to provide the
  /// session that manages the presentation.
  ///
  /// The following example presents a menu from a button:
  ///
  /// ```swift
  /// struct PopoverExample: View {
  ///     @State private var isPresented = false
  ///
  ///     var body: some View {
  ///         Button("Show menu") {
  ///             isPresented = true
  ///         }
  ///         .hieloPopover(isPresented: $isPresented) {
  ///             Text("Menu content")
  ///                 .padding()
  ///         }
  ///         .hieloHost()
  ///     }
  /// }
  /// ```
  ///
  /// The content determines the popover’s size. Use standard SwiftUI layout
  /// modifiers to configure that size. When the keyboard isn’t visible, the
  /// popover appears over the app. Keep the original input focused while the
  /// popover is presented to preserve the keyboard.
  ///
  /// Content mounts once per presentation and inherits the source's environment
  /// at presentation time. Later ancestor environment changes aren't forwarded.
  /// Keep state that must survive dismissal in the parent or a model, and dismiss
  /// by setting `isPresented` to `false`.
  ///
  /// Centered attachment components adapt toward the nearest app-window edge
  /// when no keyboard is visible.
  ///
  /// - Parameters:
  ///   - isPresented: A binding that controls presentation. Dismissing the
  ///     popover sets the binding to `false`.
  ///   - attachmentAnchor: The point used to attach the popover to its source.
  ///     The default is `.leading`.
  ///   - sourceGlass: The explicit glass appearance, overriding inherited style.
  ///     Pass `nil` for a source without glass.
  ///   - sourceShape: The source shape. The default is a capsule.
  ///   - popoverShape: The presented shape. The default is a continuously rounded
  ///     rectangle with a corner radius of 32 points.
  ///   - content: A closure that creates the popover’s content.
  /// - Returns: A view that presents the popover when `isPresented` is `true`.
  public func hieloPopover<PopoverContent: View>(
    isPresented: Binding<Bool>,
    attachmentAnchor: UnitPoint = .leading,
    sourceGlass: Glass?,
    sourceShape: HieloPopoverShape = .capsule,
    popoverShape: HieloPopoverShape = .rect(cornerRadius: 32),
    @ViewBuilder content: () -> PopoverContent
  ) -> some View {
    HieloPopover(
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
