import SwiftUI

/// The Messages-style menu. Only Photos is functional in this demo; the other
/// rows fade to a dimmed opacity to hint that Photos is the row to tap.
struct MessagesDemoMenu: View {
  let onSelectPhotos: () -> Void

  @State private var dimsUnavailableRows = false

  private let items: [(title: String, asset: String)] = [
    ("Camera", "Camera"),
    ("Photos", "Photos"),
    ("Stickers", "Stickers"),
    ("Apple Cash", "AppleCash"),
    ("Polls", "Polls"),
    ("Send Later", "SendLater"),
    ("Genmoji", "Genmoji"),
    ("Audio", "Audio"),
    ("App Store", "AppStore"),
    ("#images", "#images"),
    ("Check In", "CheckIn"),
    ("Digital Touch", "DigitalTouch"),
    ("Drawing", "Drawing"),
    ("Location", "Location"),
    ("Music", "Music"),
  ]

  var body: some View {
    ScrollView {
      VStack(spacing: 0) {
        ForEach(items, id: \.asset) { item in
          let isAvailable = item.asset == "Photos"

          Button {
            if isAvailable {
              onSelectPhotos()
            } else {
              playUnavailableHint()
            }
          } label: {
            HStack(spacing: 27) {
              Image(item.asset)
                .resizable()
                .scaledToFit()
                .frame(width: 36, height: 36)
                .clipShape(.circle)
                .accessibilityHidden(true)

              Text(item.title)
                .font(.title2)
                .multilineTextAlignment(.leading)

              Spacer()
            }
            .padding(.horizontal, 36)
            .padding(.vertical, 15)
            .contentShape(.rect)
          }
          .buttonStyle(.plain)
          .opacity(isAvailable || !dimsUnavailableRows ? 1 : 0.35)
          .accessibilityHint(isAvailable ? "Shows a photo picker." : "Not available in this demo.")
        }
      }
      .padding(.vertical, 21)
    }
    .frame(width: 300, height: 450)
    .scrollIndicators(.hidden)
  }

  /// Fades the unavailable rows out, then back in.
  private func playUnavailableHint() {
    withAnimation(.easeInOut(duration: 0.35)) {
      dimsUnavailableRows = true
    } completion: {
      withAnimation(.easeInOut(duration: 0.45)) {
        dimsUnavailableRows = false
      }
    }
  }
}
