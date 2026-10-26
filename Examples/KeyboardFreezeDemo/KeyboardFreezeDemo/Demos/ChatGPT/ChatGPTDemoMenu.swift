import SwiftUI

struct ChatGPTDemoMenu: View {
  let onSelect: () -> Void

  var body: some View {
    ScrollView {
      VStack(spacing: 0) {
        ForEach(ChatGPTDemoMenuItem.allCases) { item in
          Button(action: onSelect) {
            ChatGPTDemoMenuRow(title: item.title, systemImage: item.systemImage)
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
