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

  @Environment(\.self) private var environment
  @Environment(\.keyboardFreezeSession) private var keyboardFreeze
  @Environment(\.keyboardPopoverAnimation) private var animation
  @State private var source = KeyboardFreezeSource()
  @State private var sourceFrameInScreen = CGRect.zero
  @State private var presentationID: UUID?

  @State private var presentationTask: Task<Void, Never>?

  private var isHosted: Bool { presentationID != nil }

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
    guard isPresented, !isHosted, !sourceFrameInScreen.isEmpty else { return }
    guard let keyboardFreeze else {
      isPresented = false
      return
    }

    let id = UUID()
    presentationID = id
    source.onDetach = { [weak keyboardFreeze] in
      Task { @MainActor in
        keyboardFreeze?.dismissOverlay(id: id)
      }
    }
    let result = keyboardFreeze.presentAdaptiveOverlay(
      id: id,
      onEnded: { presentationEnded(id: id) },
      from: source,
      sourceFrame: sourceFrameInScreen,
      overlayFrame: { $0.sourceFrame },
      onOutsideTap: requestDismissal,
      content: { context in
        KeyboardPopoverOverlay(
          isPresented: $isPresented,
          sourceContent: sourceContent,
          popoverContent: popoverContent,
          context: context,
          attachmentAnchor: attachmentAnchor,
          shapeTransition: shapeTransition,
          fadesSurface: sourceGlass == nil,
          animation: animation,
          onFrameChange: { keyboardFreeze.updateOverlayFrame($0, id: id) },
          onDismissed: { keyboardFreeze.dismissOverlay(id: id) }
        )
        .environment(\.self, environment)
      }
    )

    presentationTask?.cancel()
    presentationTask = nil
    if !result.succeeded {
      presentationEnded(id: id)
    }
  }

  private var sourceSize: CGSize {
    sourceFrameInScreen.size
  }

  private func requestDismissal() {
    isPresented = false
  }

  private func presentationEnded(id: UUID) {
    guard presentationID == id else { return }
    source.onDetach = nil
    presentationTask?.cancel()
    presentationTask = nil
    var transaction = Transaction(animation: nil)
    transaction.disablesAnimations = true
    withTransaction(transaction) {
      presentationID = nil
      isPresented = false
    }
  }

  private func tearDown() {
    presentationTask?.cancel()
    presentationTask = nil
    guard let id = presentationID else { return }
    keyboardFreeze?.dismissOverlay(id: id)
    presentationEnded(id: id)
  }
}
