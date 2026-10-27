import SwiftUI

struct DemoComposerButton: View {
  var size: CGFloat = 48
  let action: () -> Void

  var body: some View {
    Button("Open menu", systemImage: "plus", action: action)
      .labelStyle(.iconOnly)
      .font(.title3)
      .foregroundStyle(.primary)
      .frame(width: size, height: size)
      .contentShape(.circle)
      .buttonStyle(.plain)
  }
}
