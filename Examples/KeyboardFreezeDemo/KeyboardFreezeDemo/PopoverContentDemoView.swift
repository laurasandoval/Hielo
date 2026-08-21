import SwiftUI

struct PopoverContentDemoView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 0.0) {
                PopoverRow(title: "Camera", systemImage: "camera.fill")
                PopoverRow(title: "Photos", systemImage: "photo.fill")
                PopoverRow(title: "Files", systemImage: "folder.fill")
                PopoverRow(title: "Network", systemImage: "network")
                PopoverRow(title: "Audio", systemImage: "waveform.path")
                PopoverRow(title: "Clipboard", systemImage: "clipboard.fill")
                PopoverRow(title: "Music", systemImage: "music.note")
                PopoverRow(title: "Notion", systemImage: "n.square.fill")
            }
            .padding(.vertical, 21.0)
        }
        .frame(width: 300, height: 450)
        .scrollIndicators(.hidden)
    }
}

struct PopoverRow: View {
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

#Preview {
    PopoverContentDemoView()
        .background(.gray.opacity(0.1))
        .cornerRadius(20)
}
