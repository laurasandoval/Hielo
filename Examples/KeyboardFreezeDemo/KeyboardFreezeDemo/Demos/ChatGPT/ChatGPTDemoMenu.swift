import SwiftUI

struct ChatGPTDemoMenu: View {
  let onSelect: () -> Void

  var body: some View {
    ScrollView {
      VStack(spacing: 0) {
        ForEach([DemoMenuItem.camera, .photos, .files]) { item in
          Button(action: onSelect) {
            DemoMenuRow(title: item.title, systemImage: item.systemImage)
              .contentShape(.rect)
          }
          .buttonStyle(.plain)
        }
      }
      .padding(.vertical, 12)
    }
    .frame(width: 300, height: 228)
    .scrollIndicators(.hidden)
  }
}
