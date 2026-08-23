import SwiftUI

struct ChatGPTDemoExpandedView: View {
  let item: ChatGPTDemoMenuItem?
  let onBack: () -> Void

  var body: some View {
    ZStack(alignment: .bottomLeading) {
      if let item {
        Text(item.title)
          .font(.largeTitle)
          .fontWeight(.semibold)
          .frame(maxWidth: .infinity, maxHeight: .infinity)

        Button("Back", systemImage: "chevron.left", action: onBack)
          .labelStyle(.iconOnly)
          .font(.title3)
          .frame(width: 48, height: 48)
          .glassEffect(.regular.interactive())
          .foregroundStyle(.primary)
          .padding(28)
      }
    }
    // Screen width - 8pt per side
    .containerRelativeFrame(.horizontal) { width, _ in
      width - 16
    }
    .frame(height: 585)
  }
}

#Preview("Photos") {
  ChatGPTDemoExpandedView(item: .photos) {}
}
