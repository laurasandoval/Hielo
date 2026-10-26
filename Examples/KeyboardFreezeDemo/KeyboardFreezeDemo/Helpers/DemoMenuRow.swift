import SwiftUI

struct DemoMenuRow: View {
    let title: String
    let systemImage: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(.primary)
                .frame(width: 44, height: 44)
                .background(.quaternary)
                .clipShape(Circle())

            Text(title)
                .font(.system(size: 20))
                .multilineTextAlignment(.leading)

            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
    }
}

