import Foundation

enum DemoMenuItem: CaseIterable, Identifiable {
  case camera
  case photos
  case files
  case network
  case audio
  case clipboard
  case music
  case notion

  var id: Self { self }

  var title: String {
    switch self {
    case .camera: "Camera"
    case .photos: "Photos"
    case .files: "Files"
    case .network: "Network"
    case .audio: "Audio"
    case .clipboard: "Clipboard"
    case .music: "Music"
    case .notion: "Notion"
    }
  }

  var systemImage: String {
    switch self {
    case .camera: "camera"
    case .photos: "photo"
    case .files: "paperclip"
    case .network: "network"
    case .audio: "waveform.path"
    case .clipboard: "clipboard.fill"
    case .music: "music.note"
    case .notion: "n.square.fill"
    }
  }
}
