import SwiftUI

struct DemoComposerButton: View {
  let action: () -> Void

  var body: some View {
    Button("Open menu", systemImage: "plus", action: action)
      .labelStyle(.iconOnly)
      .font(.title3)
      .foregroundStyle(.primary)
      .frame(width: 48, height: 48)
      .contentShape(.circle)
      .buttonStyle(.plain)
  }
}
