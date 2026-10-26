import SwiftUI

struct KeyboardPopoverOverlay<SourceContent: View, PopoverContent: View>: View {
  @Binding var isPresented: Bool

  let sourceContent: SourceContent
  let popoverContent: PopoverContent
  let context: KeyboardFreeze.Context
  let attachmentAnchor: UnitPoint
  let shapeTransition: KeyboardPopoverShapeTransition
  let fadesSurface: Bool
  let animation: Animation?
  let onFrameChange: @MainActor (CGRect) -> Void
  let onDismissed: @MainActor () -> Void

  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @State private var destinationSize = CGSize.zero
  @State private var expansionProgress = 0.0
  @State private var dragOffset = CGSize.zero
  @State private var isDismissing = false

  var body: some View {
    ZStack {
      KeyboardPopoverSurface(
        sourceContent: sourceContent,
        popoverContent: popoverContent,
        sourceSize: sourceFrame.size,
        destinationSize: destinationFrame.size,
        currentSize: currentSurfaceFrame.size,
        shape: surfaceShape,
        expansionProgress: expansionProgress,
        fadesSurface: fadesSurface,
        onContentSizeChange: updateContentSize
      )
      .scaleEffect(dragScale)
      .offset(dragOffset)
      .contentShape(surfaceShape)
      .gesture(
        KeyboardPopoverPanGesture(
          isEnabled: expansionProgress == 1 && !isDismissing,
          onChanged: updateDrag,
          onEnded: endDrag,
          onCancelled: springBack
        )
      )
      .position(surfaceCenter)
    }
    .frame(width: destinationFrame.width, height: destinationFrame.height)
    .opacity(destinationSize == .zero ? 0 : 1)
    .task(id: destinationSize == .zero) {
      guard destinationSize != .zero, expansionProgress == 0 else { return }
      await expand()
    }
    .onChange(of: isPresented) { _, newValue in
      if !newValue {
        beginDismissal()
      }
    }
    .accessibilityElement(children: .contain)
    .accessibilityAction(.escape, beginDismissal)
  }

  private var sourceFrame: CGRect { context.sourceFrame }

  private var destinationFrame: CGRect {
    let anchor = context.keyboardFrame.isEmpty
      ? KeyboardPopoverPlacement.adaptiveAttachmentAnchor(
          preferredAnchor: attachmentAnchor,
          sourceFrame: sourceFrame,
          availableBounds: context.safeAreaBounds
        )
      : attachmentAnchor
    return KeyboardPopoverPlacement.destinationFrame(
      sourceFrame: sourceFrame,
      destinationSize: destinationSize,
      attachmentAnchor: anchor,
      availableBounds: context.safeAreaBounds
    )
  }

  private func updateContentSize(_ size: CGSize) {
    guard !isDismissing, size.width > 0, size.height > 0,
      size.width.isFinite, size.height.isFinite, size != destinationSize
    else { return }
    destinationSize = size
    onFrameChange(destinationFrame)
  }

  private var localSourceFrame: CGRect {
    sourceFrame.offsetBy(
      dx: -destinationFrame.minX,
      dy: -destinationFrame.minY
    )
  }

  private var currentSurfaceFrame: CGRect {
    CGRect(
      x: interpolate(localSourceFrame.minX, 0),
      y: interpolate(localSourceFrame.minY, 0),
      width: interpolate(localSourceFrame.width, destinationFrame.width),
      height: interpolate(localSourceFrame.height, destinationFrame.height)
    )
  }

  private var surfaceCenter: CGPoint {
    CGPoint(x: currentSurfaceFrame.midX, y: currentSurfaceFrame.midY)
  }

  private var surfaceShape: UnevenRoundedRectangle {
    shapeTransition.resolveShape(
      sourceSize: localSourceFrame.size,
      destinationSize: destinationFrame.size,
      expansionProgress: expansionProgress
    )
  }

  private var dragScale: Double {
    KeyboardPopoverDragBehavior.scale(for: dragOffset)
  }

  private func updateDrag(_ translation: CGSize) {
    guard expansionProgress == 1, !isDismissing else { return }
    dragOffset = KeyboardPopoverDragBehavior.rubberBandedOffset(
      for: translation
    )
  }

  private func endDrag(
    _ translation: CGSize,
    _ predictedEndTranslation: CGSize
  ) {
    guard expansionProgress == 1, !isDismissing else { return }
    if KeyboardPopoverDragBehavior.shouldDismiss(
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

    withAnimation(reduceMotion ? nil : animation) {
      expansionProgress = 1
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
    if isPresented {
      isPresented = false
    }

    guard !reduceMotion, animation != nil else {
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
