import SwiftUI

struct DemoComposerButton: View {
  let action: () -> Void

  var body: some View {
    Button("Open menu", systemImage: "plus", action: action)
      .labelStyle(.iconOnly)
      .font(.title3)
      .foregroundStyle(.primary)
      .frame(width: 42, height: 42)
      .contentShape(.circle)
      .buttonStyle(.plain)
  }
}
