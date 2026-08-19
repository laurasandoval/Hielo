import SwiftUI

struct PopoverPositioner: UIViewRepresentable {
  let targetFrame: CGRect

  func makeUIView(context: Context) -> PopoverPositioningView {
    PopoverPositioningView(targetFrame: targetFrame)
  }

  func updateUIView(
    _ uiView: PopoverPositioningView,
    context: Context
  ) {
    uiView.targetFrame = targetFrame
  }
}
