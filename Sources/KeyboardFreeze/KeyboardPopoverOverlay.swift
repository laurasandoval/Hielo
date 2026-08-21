import SwiftUI

struct KeyboardPopoverOverlay<SourceContent: View, PopoverContent: View>: View {
  @Binding var isPresented: Bool

  let sourceContent: SourceContent
  let popoverContent: PopoverContent
  let sourceFrame: CGRect
  let destinationFrame: CGRect
  let shapeTransition: KeyboardPopoverShapeTransition
  let fadesSurface: Bool
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
      .simultaneousGesture(dragGesture)
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
    KeyboardPopoverGeometry.dragScale(for: dragOffset)
  }

  private var dragGesture: some Gesture {
    DragGesture(minimumDistance: 4)
      .onChanged { value in
        guard expansionProgress == 1, !isDismissing else { return }
        dragOffset = KeyboardPopoverGeometry.rubberBandedOffset(
          for: value.translation
        )
      }
      .onEnded { value in
        guard expansionProgress == 1, !isDismissing else { return }
        if KeyboardPopoverGeometry.shouldDismiss(
          translation: value.translation,
          predictedEndTranslation: value.predictedEndTranslation
        ) {
          isPresented = false
          beginDismissal()
        } else {
          springBack()
        }
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
      withAnimation(.smooth(duration: 0.2)) {
        expansionProgress = 1
      }
    }
  }

  private func springBack() {
    withAnimation(.smooth(duration: 0.2)) {
      dragOffset = .zero
    }
  }

  private func beginDismissal() {
    guard !isDismissing else { return }
    isDismissing = true
    if isPresented {
      isPresented = false
    }

    guard !reduceMotion else {
      completeDismissal()
      return
    }

    withAnimation(.smooth(duration: 0.2), completionCriteria: .removed) {
      expansionProgress = 0
      dragOffset = .zero
    } completion: {
      completeDismissal()
    }
  }

  private func completeDismissal() {
    onSourceHandoff()
    Task { @MainActor in
      // Keep the collapsed overlay mounted through at least one 30 Hz display frame
      // so the restored source is ready before the keyboard-window host is removed.
      try? await Task.sleep(for: .milliseconds(34))
      onDismissed()
    }
  }
}
