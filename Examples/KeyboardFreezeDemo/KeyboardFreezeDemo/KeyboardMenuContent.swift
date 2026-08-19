import SwiftUI

struct KeyboardMenuContent: View {
  let sourceFrame: CGRect

  @State private var isVisible = false

  var body: some View {
    Text("Hello World")
      .font(.headline)
      .opacity(isVisible ? 1 : 0)
      .frame(width: 250, height: 250, alignment: .center)
      .background {
        PopoverPositioner(targetFrame: targetFrame)
      }
      .presentationCompactAdaptation(.popover)
      .task(animateContentIn)
  }

  private var targetFrame: CGRect {
    CGRect(
      x: sourceFrame.minX - 16,
      y: sourceFrame.midY - 125,
      width: 250,
      height: 250
    )
  }

  private func animateContentIn() async {
    try? await Task.sleep(for: .milliseconds(100))
    withAnimation(.snappy(duration: 0.3, extraBounce: 0)) {
      isVisible = true
    }
  }
}

#Preview {
  KeyboardMenuContent(
    sourceFrame: CGRect(x: 12, y: 440, width: 48, height: 48)
  )
}
