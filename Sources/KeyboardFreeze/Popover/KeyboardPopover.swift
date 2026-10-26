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
  @Environment(\.keyboardPopoverAnimation) private var animation
  @State private var source = KeyboardFreezeSource()
  @State private var sourceFrameInScreen = CGRect.zero
  @State private var destinationSize = CGSize.zero
  @State private var isHosted = false
  @State private var presentationTask: Task<Void, Never>?

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
        schedulePresentation()
      } else {
        presentationTask?.cancel()
        presentationTask = nil
      }
    }
    .onDisappear(perform: tearDown)
  }

  private func schedulePresentation() {
    guard isPresented, !isHosted else { return }

    presentationTask?.cancel()
    presentationTask = Task { @MainActor in
      try? await Task.sleep(for: KeyboardPopoverMotion.geometrySettleDelay)
      guard !Task.isCancelled else { return }
      presentIfReady()
    }
  }

  private func presentIfReady() {
    guard
      KeyboardPopoverPresentationReadiness.canPresent(
        isPresented: isPresented,
        isHosted: isHosted,
        resolvedSourceFrame: source.frameInScreen,
        measuredSourceFrame: sourceFrameInScreen,
        destinationSize: destinationSize
      )
    else { return }
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
          animation: animation,
          onSourceHandoff: prepareSourceHandoff,
          onDismissed: finishDismissal
        )
      }
    )

    if result.succeeded {
      presentationTask?.cancel()
      presentationTask = nil
      isHosted = true
    } else {
      presentationTask?.cancel()
      presentationTask = nil
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
    presentationTask?.cancel()
    presentationTask = nil
    keyboardFreeze?.dismissOverlay()
    isHosted = false
  }

  private func tearDown() {
    presentationTask?.cancel()
    presentationTask = nil
    guard isHosted else { return }
    keyboardFreeze?.dismissOverlay()
    isHosted = false
  }
}
