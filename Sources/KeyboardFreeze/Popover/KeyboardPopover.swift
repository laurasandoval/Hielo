import SwiftUI

/// A source view that expands into custom content over a frozen keyboard or app.
///
/// Create this view with a `keyboardPopover` view modifier.
/// The nearest ``View/keyboardFreeze(_:lifecycle:)`` modifier supplies the
/// keyboard-freeze session used for presentation.
@MainActor
struct KeyboardPopover<SourceContent: View, PopoverContent: View>: View {
  @Binding private var isPresented: Bool

  private let attachmentAnchor: UnitPoint
  private let sourceGlass: Glass?
  private let shapeTransition: KeyboardPopoverShapeTransition
  private let sourceContent: SourceContent
  private let popoverContent: PopoverContent

  @Environment(\.keyboardFreezeSession) private var keyboardFreeze
  @State private var source = KeyboardFreezeSource()
  @State private var sourceFrameInScreen = CGRect.zero
  @State private var destinationSize = CGSize.zero
  @State private var isHosted = false

  init(
    isPresented: Binding<Bool>,
    attachmentAnchor: UnitPoint = .leading,
    sourceGlass: Glass? = .regular.interactive(),
    sourceShape: KeyboardPopoverShape = .capsule,
    popoverShape: KeyboardPopoverShape = .rect(cornerRadius: 32),
    @ViewBuilder source: () -> SourceContent,
    @ViewBuilder content: () -> PopoverContent
  ) {
    _isPresented = isPresented
    self.attachmentAnchor = attachmentAnchor
    self.sourceGlass = sourceGlass
    shapeTransition = KeyboardPopoverShapeTransition(
      sourceShape: sourceShape,
      popoverShape: popoverShape
    )
    sourceContent = source()
    popoverContent = content()
  }

  var body: some View {
    ZStack {
      if isHosted {
        Color.clear
          .frame(width: sourceSize.width, height: sourceSize.height)
      } else {
        sourceContent
          .glassEffect(
            sourceGlass ?? .identity,
            in: shapeTransition.sourceShape
          )
          .glassEffectTransition(.identity)
      }
    }
    .keyboardFreezeSource(source)
    .accessibilityHidden(isHosted)
    .background {
      popoverContent
        .fixedSize()
        .hidden()
        .accessibilityHidden(true)
        .allowsHitTesting(false)
        .onGeometryChange(for: CGSize.self) { proxy in
          proxy.size
        } action: { newSize in
          destinationSize = newSize
          presentIfReady()
        }
    }
    .onChange(of: source.frameInScreen) {
      // UIKit identifies the source's app window while SwiftUI supplies screen
      // coordinates that stay correct when the overlay crosses window boundaries.
      presentIfReady()
    }
    .onGeometryChange(for: CGRect.self) { proxy in
      proxy.frame(in: .global)
    } action: { newFrame in
      sourceFrameInScreen = newFrame
      presentIfReady()
    }
    .onChange(of: isPresented) { _, newValue in
      if newValue {
        presentIfReady()
      }
    }
    .onDisappear(perform: tearDown)
  }

  private func presentIfReady() {
    guard isPresented, !isHosted else { return }
    guard sourceSize.width > 0, sourceSize.height > 0 else { return }
    guard !sourceFrameInScreen.isEmpty else { return }
    guard destinationSize.width > 0, destinationSize.height > 0 else { return }
    guard let keyboardFreeze else {
      isPresented = false
      return
    }

    let result = keyboardFreeze.presentAdaptiveOverlay(
      from: source,
      sourceFrame: sourceFrameInScreen,
      overlayFrame: destinationFrame,
      onOutsideTap: requestDismissal,
      content: { context in
        KeyboardPopoverOverlay(
          isPresented: $isPresented,
          sourceContent: sourceContent,
          popoverContent: popoverContent,
          sourceFrame: context.sourceFrame,
          destinationFrame: destinationFrame(context),
          shapeTransition: shapeTransition,
          fadesSurface: sourceGlass == nil,
          onSourceHandoff: prepareSourceHandoff,
          onDismissed: finishDismissal
        )
      }
    )

    if result.succeeded {
      isHosted = true
    } else {
      isPresented = false
    }
  }

  private func destinationFrame(
    _ context: KeyboardFreeze.Context
  ) -> CGRect {
    let resolvedAnchor =
      if context.keyboardFrame.isEmpty {
        KeyboardPopoverPlacement.adaptiveAttachmentAnchor(
          preferredAnchor: attachmentAnchor,
          sourceFrame: context.sourceFrame,
          availableBounds: context.safeAreaBounds
        )
      } else {
        attachmentAnchor
      }

    return KeyboardPopoverPlacement.destinationFrame(
      sourceFrame: context.sourceFrame,
      destinationSize: destinationSize,
      attachmentAnchor: resolvedAnchor,
      availableBounds: context.safeAreaBounds
    )
  }

  private var sourceSize: CGSize {
    sourceFrameInScreen.size
  }

  private func requestDismissal() {
    isPresented = false
  }

  private func prepareSourceHandoff() {
    var transaction = Transaction()
    transaction.disablesAnimations = true
    withTransaction(transaction) {
      isHosted = false
    }
  }

  private func finishDismissal() {
    keyboardFreeze?.dismissOverlay()
    isHosted = false
  }

  private func tearDown() {
    guard isHosted else { return }
    keyboardFreeze?.dismissOverlay()
    isHosted = false
  }
}
