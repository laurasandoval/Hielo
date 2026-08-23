import SwiftUI

struct HieloPopoverOverlay<SourceContent: View, PopoverContent: View>: View {
  @Binding var isPresented: Bool

  let sourceContent: SourceContent
  let popoverContent: PopoverContent
  let context: HieloSession.Context
  let attachmentAnchor: UnitPoint
  let shapeTransition: HieloPopoverShapeTransition
  let fadesSurface: Bool
  let animation: Animation?
  let interactionRegion: HieloOverlayInteractionRegion
  let cornerRadiusResolver: HieloPopoverCornerRadiusResolver
  let onDismissed: @MainActor () -> Void

  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @State private var destinationFrame = CGRect.zero
  @State private var surfaceCornerRadius: CGFloat = 32
  @State private var dragDismissDisabled = false
  @State private var requestedDestinationSize = CGSize.zero
  @State private var requestedCornerRadius: HieloPopoverCornerRadius?
  @State private var requestedPlacement: HieloPopoverPlacement = .source
  @State private var expansionProgress = 0.0
  @State private var scalesTransitionContent = false
  @State private var rendersTransitionSurfaces = false
  @State private var supportsContentTransition = false
  @State private var initialExpansionCompleted = false
  @State private var dragOffset = CGSize.zero
  @State private var isDismissing = false
  @State private var configurationUpdateTask: Task<Void, Never>?

  var body: some View {
    ZStack(alignment: .topLeading) {
      HieloPopoverSurface(
        sourceContent: sourceContent,
        popoverContent: popoverContent,
        sourceSize: localSourceFrame.size,
        destinationSize: destinationFrame.size,
        currentSize: currentSurfaceFrame.size,
        shape: surfaceShape,
        cornerRadius: currentCornerRadius,
        expansionProgress: expansionProgress,
        fadesSurface: fadesSurface,
        scalesTransitionContent: scalesTransitionContent,
        rendersTransitionSurfaces: rendersTransitionSurfaces,
        onContentSizeChange: updateDestinationSize
      )
      .allowsHitTesting(
        !supportsContentTransition
          || (initialExpansionCompleted && scalesTransitionContent)
      )
      .scaleEffect(dragScale)
      .offset(dragOffset)
      .contentShape(surfaceShape)
      .gesture(
        HieloPopoverPanGesture(
          isEnabled: expansionProgress == 1 && !isDismissing && !dragDismissDisabled,
          onChanged: updateDrag,
          onEnded: endDrag,
          onCancelled: springBack
        )
      )
      .position(surfaceCenter)
      .onGeometryChange(for: CGRect.self) { proxy in
        proxy.frame(in: .global)
      } action: { frame in
        interactionRegion.frame = frame
      }
    }
    .frame(width: windowBounds.width, height: windowBounds.height)
    .onPreferenceChange(HieloPopoverCornerRadiusPreferenceKey.self) { value in
      requestCornerRadius(value)
    }
    .onPreferenceChange(HieloPopoverContentTransitionPreferenceKey.self) { value in
      supportsContentTransition = value
      primeContentTransitionIfReady()
    }
    .onPreferenceChange(HieloPopoverDragDismissDisabledPreferenceKey.self) { value in
      dragDismissDisabled = value
      if value {
        springBack()
      }
    }
    .onPreferenceChange(HieloPopoverPlacementPreferenceKey.self) { value in
      requestPlacement(value)
    }
    .opacity(destinationFrame.isEmpty ? 0 : 1)
    .task(id: destinationFrame.isEmpty) {
      guard !destinationFrame.isEmpty, expansionProgress == 0 else { return }
      await expand()
    }
    .onChange(of: isPresented) { _, newValue in
      if !newValue {
        beginDismissal()
      }
    }
    .onDisappear {
      configurationUpdateTask?.cancel()
    }
    .accessibilityElement(children: .contain)
    .accessibilityAction(.escape, beginDismissal)
  }

  private var sourceFrame: CGRect { context.sourceFrame }
  private var windowBounds: CGRect { context.windowBounds }
  private var safeAreaBounds: CGRect { context.safeAreaBounds }

  private var resolvedAttachmentAnchor: UnitPoint {
    context.keyboardFrame.isEmpty
      ? HieloPopoverPlacementResolver.adaptiveAttachmentAnchor(
          preferredAnchor: attachmentAnchor,
          sourceFrame: sourceFrame,
          availableBounds: safeAreaBounds
        )
      : attachmentAnchor
  }

  private var localSourceFrame: CGRect {
    sourceFrame.offsetBy(dx: -windowBounds.minX, dy: -windowBounds.minY)
  }

  private var localDestinationFrame: CGRect {
    destinationFrame.offsetBy(dx: -windowBounds.minX, dy: -windowBounds.minY)
  }

  private var currentSurfaceFrame: CGRect {
    CGRect(
      x: interpolate(localSourceFrame.minX, localDestinationFrame.minX),
      y: interpolate(localSourceFrame.minY, localDestinationFrame.minY),
      width: interpolate(localSourceFrame.width, localDestinationFrame.width),
      height: interpolate(localSourceFrame.height, localDestinationFrame.height)
    )
  }

  private var surfaceCenter: CGPoint {
    CGPoint(x: currentSurfaceFrame.midX, y: currentSurfaceFrame.midY)
  }

  private var effectiveShapeTransition: HieloPopoverShapeTransition {
    HieloPopoverShapeTransition(
      sourceShape: shapeTransition.sourceShape,
      popoverShape: requestedCornerRadius == nil
        ? shapeTransition.popoverShape
        : .rect(cornerRadius: surfaceCornerRadius)
    )
  }

  private var surfaceShape: UnevenRoundedRectangle {
    effectiveShapeTransition.resolveShape(
      sourceSize: sourceFrame.size,
      destinationSize: destinationFrame.size,
      expansionProgress: expansionProgress
    )
  }

  private var currentCornerRadius: CGFloat {
    effectiveShapeTransition.resolve(
      sourceSize: sourceFrame.size,
      destinationSize: destinationFrame.size,
      expansionProgress: expansionProgress
    ).topLeading
  }

  private var dragScale: Double {
    HieloPopoverDragBehavior.scale(for: dragOffset)
  }

  private func updateDestinationSize(_ size: CGSize) {
    guard !isDismissing, size.width > 0, size.height > 0,
      size.width.isFinite, size.height.isFinite else { return }
    guard
      abs(size.width - requestedDestinationSize.width) >= 0.5
        || abs(size.height - requestedDestinationSize.height) >= 0.5
    else { return }

    requestedDestinationSize = size
    scheduleConfigurationUpdate()
  }

  private func requestCornerRadius(_ newValue: HieloPopoverCornerRadius?) {
    guard newValue != requestedCornerRadius else { return }
    requestedCornerRadius = newValue
    scheduleConfigurationUpdate()
  }

  private func requestPlacement(_ newValue: HieloPopoverPlacement) {
    guard newValue != requestedPlacement else { return }
    requestedPlacement = newValue
    scheduleConfigurationUpdate()
  }

  private func scheduleConfigurationUpdate() {
    guard !isDismissing else { return }
    configurationUpdateTask?.cancel()
    configurationUpdateTask = Task { @MainActor in
      await Task.yield()
      guard !Task.isCancelled, !isDismissing else { return }
      applyRequestedConfiguration()
    }
  }

  private func applyRequestedConfiguration() {
    guard !isDismissing, requestedDestinationSize != .zero else { return }
    let isInitialMeasurement = destinationFrame.isEmpty
    let targetFrame = resolvedDestinationFrame(
      size: requestedDestinationSize,
      placement: requestedPlacement
    )
    let changesSize =
      abs(targetFrame.width - destinationFrame.width) >= 0.5
      || abs(targetFrame.height - destinationFrame.height) >= 0.5
    let targetCornerRadius = resolvedCornerRadius(
      requestedCornerRadius,
      for: targetFrame
    )
    let changes = {
      if changesSize && initialExpansionCompleted {
        scalesTransitionContent = true
        rendersTransitionSurfaces = true
      }
      destinationFrame = targetFrame
      surfaceCornerRadius = targetCornerRadius
    }

    withAnimation(isInitialMeasurement || reduceMotion ? nil : animation, changes)
  }

  private func resolvedCornerRadius(
    _ cornerRadius: HieloPopoverCornerRadius?,
    for frame: CGRect
  ) -> CGFloat {
    guard let cornerRadius else {
      return shapeTransition.popoverShape.cornerRadii(for: frame.size).topLeading
    }
    return cornerRadiusResolver.resolve(cornerRadius, for: frame) ?? 32
  }

  private func resolvedDestinationFrame(
    size: CGSize,
    placement: HieloPopoverPlacement
  ) -> CGRect {
    switch placement {
    case .source:
      HieloPopoverPlacementResolver.sourceDestinationFrame(
        sourceFrame: sourceFrame,
        destinationSize: size,
        attachmentAnchor: resolvedAttachmentAnchor,
        availableBounds: safeAreaBounds
      )
    case .container(let alignment, let inset):
      HieloPopoverPlacementResolver.containerDestinationFrame(
        destinationSize: size,
        alignment: alignment,
        inset: inset,
        containerBounds: windowBounds
      )
    }
  }

  private func updateDrag(_ translation: CGSize) {
    guard expansionProgress == 1, !isDismissing, !dragDismissDisabled else { return }
    dragOffset = HieloPopoverDragBehavior.rubberBandedOffset(for: translation)
  }

  private func endDrag(
    _ translation: CGSize,
    _ predictedEndTranslation: CGSize
  ) {
    guard expansionProgress == 1, !isDismissing, !dragDismissDisabled else { return }
    if HieloPopoverDragBehavior.shouldDismiss(
      translation: translation,
      predictedEndTranslation: predictedEndTranslation
    ) {
      isPresented = false
      beginDismissal()
    } else {
      springBack()
    }
  }

  private func interpolate(_ collapsedValue: Double, _ expandedValue: Double) -> Double {
    collapsedValue + (expandedValue - collapsedValue) * expansionProgress
  }

  private func expand() async {
    await Task.yield()
    guard !Task.isCancelled, !isDismissing, isPresented else { return }

    withAnimation(reduceMotion ? nil : animation, completionCriteria: .removed) {
      expansionProgress = 1
    } completion: {
      guard !isDismissing else { return }
      initialExpansionCompleted = true
      primeContentTransitionIfReady()
    }
  }

  private func primeContentTransitionIfReady() {
    guard
      supportsContentTransition,
      initialExpansionCompleted,
      !scalesTransitionContent,
      !isDismissing
    else { return }

    var transaction = Transaction(animation: nil)
    transaction.disablesAnimations = true
    withTransaction(transaction) {
      scalesTransitionContent = true
    }
  }

  private func springBack() {
    withAnimation(reduceMotion ? nil : animation) {
      dragOffset = .zero
    }
  }

  private func beginDismissal() {
    guard !isDismissing else { return }
    isDismissing = true
    scalesTransitionContent = false
    rendersTransitionSurfaces = false
    if isPresented {
      isPresented = false
    }

    guard !reduceMotion, animation != nil else {
      expansionProgress = 0
      completeDismissal()
      return
    }

    withAnimation(
      reduceMotion ? nil : animation,
      completionCriteria: .removed
    ) {
      expansionProgress = 0
      dragOffset = .zero
    } completion: {
      completeDismissal()
    }
  }

  private func completeDismissal() {
    // Replace the collapsed overlay without displaying two glass sources together.
    var transaction = Transaction(animation: nil)
    transaction.disablesAnimations = true
    withTransaction(transaction) {
      onDismissed()
    }
  }
}
