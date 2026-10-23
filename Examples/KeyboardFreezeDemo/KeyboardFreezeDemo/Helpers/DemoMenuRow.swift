import SwiftUI

struct DemoMenuRow: View {
    let title: String
    let systemImage: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(.secondary)
                .frame(width: 36, height: 36)
                .background(.tertiary)
                .clipShape(Circle())

            Text(title)
                .font(.title2)
                .multilineTextAlignment(.leading)

            Spacer()
        }
        .padding(.horizontal, 36.0)
        .padding(.vertical, 15.0)
    }
}

