import SwiftUI

/// A source view that expands into custom content over a frozen keyboard or app.
///
/// Create this view with a `hieloPopover` view modifier.
/// The nearest ``View/hieloHost()`` modifier supplies the
/// session used for presentation.
@MainActor
struct HieloPopover<SourceContent: View, PopoverContent: View>: View {
  @Binding private var isPresented: Bool

  private let attachmentAnchor: UnitPoint
  private let sourceGlass: Glass?
  private let shapeTransition: HieloPopoverShapeTransition
  private let onDismiss: (() -> Void)?
  private let sourceContent: SourceContent
  private let popoverContent: PopoverContent

  @Environment(\.self) private var environment
  @Environment(\.hieloSession) private var session
  @Environment(\.hieloPopoverAnimation) private var animation
  @State private var source = HieloSource()
  @State private var sourceFrameInScreen = CGRect.zero
  @State private var presentationID: UUID?

  @State private var presentationTask: Task<Void, Never>?

  private var isHosted: Bool { presentationID != nil }

  init(
    isPresented: Binding<Bool>,
    attachmentAnchor: UnitPoint = .leading,
    sourceGlass: Glass? = .regular.interactive(),
    sourceShape: HieloPopoverShape = .capsule,
    popoverShape: HieloPopoverShape = .rect(cornerRadius: 32),
    onDismiss: (() -> Void)? = nil,
    @ViewBuilder source: () -> SourceContent,
    @ViewBuilder content: () -> PopoverContent
  ) {
    _isPresented = isPresented
    self.attachmentAnchor = attachmentAnchor
    self.sourceGlass = sourceGlass
    self.onDismiss = onDismiss
    shapeTransition = HieloPopoverShapeTransition(
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
    .hieloSource(source)
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
      try? await Task.sleep(for: HieloPopoverMotion.geometrySettleDelay)
      guard !Task.isCancelled else { return }
      presentIfReady()
    }
  }

  private func presentIfReady() {
    guard isPresented, !isHosted, !sourceFrameInScreen.isEmpty else { return }
    guard let session else {
      isPresented = false
      return
    }

    let id = UUID()
    presentationID = id
    source.onDetach = { [weak session] in
      Task { @MainActor in
        session?.dismissOverlay(id: id)
      }
    }
    let result = session.presentAdaptiveOverlay(
      id: id,
      onEnded: { presentationEnded(id: id) },
      from: source,
      sourceFrame: sourceFrameInScreen,
      overlayFrame: { $0.sourceFrame },
      onOutsideTap: requestDismissal,
      content: { context in
        HieloPopoverOverlay(
          isPresented: $isPresented,
          sourceContent: sourceContent,
          popoverContent: popoverContent,
          context: context,
          attachmentAnchor: attachmentAnchor,
          shapeTransition: shapeTransition,
          fadesSurface: sourceGlass == nil,
          animation: animation,
          onFrameChange: { session.updateOverlayFrame($0, id: id) },
          onDismissed: { session.dismissOverlay(id: id) }
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
    onDismiss?()
  }

  private func tearDown() {
    presentationTask?.cancel()
    presentationTask = nil
    guard let id = presentationID else { return }
    session?.dismissOverlay(id: id)
    presentationEnded(id: id)
  }
}
