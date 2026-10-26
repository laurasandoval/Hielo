import SwiftUI

struct KeyboardPopoverOverlay<SourceContent: View, PopoverContent: View>: View {
  @Binding var isPresented: Bool

  let sourceContent: SourceContent
  let popoverContent: PopoverContent
  let sourceFrame: CGRect
  let destinationFrame: CGRect
  let shapeTransition: KeyboardPopoverShapeTransition
  let fadesSurface: Bool
  let animation: Animation?
  let onSourceHandoff: @MainActor () -> Void
  let onDismissed: @MainActor () -> Void

  @Environment(\.accessibilityReduceMotion) private var reduceMotion
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
        fadesSurface: fadesSurface
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
    .task {
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
    guard !isDismissing else { return }

    if reduceMotion {
      expansionProgress = 1
    } else {
      withAnimation(reduceMotion ? nil : animation) {
        expansionProgress = 1
      }
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
      onSourceHandoff()
      onDismissed()
    }
  }
}
