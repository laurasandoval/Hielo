import SwiftUI

struct KeyboardPopoverOverlay<SourceContent: View, PopoverContent: View>: View {
  @Binding var isPresented: Bool

  let sourceContent: SourceContent
  let popoverContent: PopoverContent
  let sourceFrame: CGRect
  let destinationFrame: CGRect
  let onDismissed: @MainActor () -> Void

  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @State private var expansionProgress = 0.0
  @State private var dragOffset = CGSize.zero
  @State private var isDismissing = false

  var body: some View {
    ZStack {
      ZStack {
        sourceContent
          .frame(width: sourceFrame.width, height: sourceFrame.height)
          .scaleEffect(sourceContentScale, anchor: .center)
          .position(
            x: currentSurfaceFrame.width / 2,
            y: currentSurfaceFrame.height / 2
          )
          .blur(radius: expansionProgress * 8)
          .opacity(1 - expansionProgress)
          .allowsHitTesting(false)
          .accessibilityHidden(true)

        popoverContent
          .frame(width: destinationFrame.width, height: destinationFrame.height)
          .scaleEffect(contentScale, anchor: .center)
          .opacity(expansionProgress)
          .position(
            x: currentSurfaceFrame.width / 2,
            y: currentSurfaceFrame.height / 2
          )
      }
      .frame(
        width: currentSurfaceFrame.width,
        height: currentSurfaceFrame.height
      )
      .clipShape(.rect(cornerRadius: cornerRadius))
      .glassEffect(
        .regular.interactive(),
        in: .rect(cornerRadius: cornerRadius)
      )
      .scaleEffect(dragScale)
      .offset(dragOffset)
      .contentShape(.rect(cornerRadius: cornerRadius))
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

  private var contentScale: Double {
    guard destinationFrame.width > 0 else { return 1 }
    return currentSurfaceFrame.width / destinationFrame.width
  }

  private var sourceContentScale: Double {
    min(max(1 + expansionProgress * 0.5, 1), 1.5)
  }

  private var cornerRadius: Double {
    let collapsedRadius = min(localSourceFrame.width, localSourceFrame.height) / 2
    let expandedRadius = min(
      32,
      min(destinationFrame.width, destinationFrame.height) / 2
    )
    return interpolate(collapsedRadius, expandedRadius)
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

    guard !reduceMotion else {
      onDismissed()
      return
    }

    withAnimation(.smooth(duration: 0.2)) {
      expansionProgress = 0
      dragOffset = .zero
    } completion: {
      onDismissed()
    }
  }
}
