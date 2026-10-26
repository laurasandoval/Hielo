import SwiftUI

struct DemoRow: View {
  let title: LocalizedStringKey
  let subtitle: LocalizedStringKey
  let imageName: String

  var body: some View {
    HStack(spacing: 16) {
      Image(imageName)
        .resizable()
        .frame(width: 48, height: 48)
        .clipShape(RoundedRectangle(cornerRadius: 12.0, style: .continuous))
        .accessibilityHidden(true)

      VStack(alignment: .leading) {
        Text(title)
        Text(subtitle)
          .font(.subheadline)
          .foregroundStyle(.secondary)
      }
    }
  }
}

#Preview("ChatGPT") {
  DemoRow(
    title: "ChatGPT",
    subtitle: "Inline popover button",
    imageName: "AppIcon-ChatGPT"
  )
  .padding()
}
