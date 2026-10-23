import SwiftUI

struct ChatGPTDemoMenu: View {
  let onSelect: () -> Void

  var body: some View {
    ScrollView {
      VStack(spacing: 0) {
        ForEach(DemoMenuItem.allCases) { item in
          Button(action: onSelect) {
            DemoMenuRow(title: item.title, systemImage: item.systemImage)
              .contentShape(.rect)
          }
          .buttonStyle(.plain)
        }
      }
      .padding(.vertical, 21)
    }
    .frame(width: 300, height: 450)
    .scrollIndicators(.hidden)
  }
}
