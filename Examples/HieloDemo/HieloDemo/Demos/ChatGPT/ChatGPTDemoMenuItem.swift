import Foundation

enum ChatGPTDemoMenuItem: CaseIterable, Identifiable {
  case camera
  case photos
  case files

  var id: Self { self }

  var title: String {
    switch self {
    case .camera: "Camera"
    case .photos: "Photos"
    case .files: "Files"
    }
  }

  var systemImage: String {
    switch self {
    case .camera: "camera"
    case .photos: "photo"
    case .files: "paperclip"
    }
  }
}
