import Observation
import SwiftUI

/// Owns the presentation behind a Hielo host.
@MainActor
@Observable
final class HieloSession {
  /// Geometry in the host window's coordinate space, measured in points.
  struct Context: Sendable {
    let windowBounds: CGRect
    let safeAreaBounds: CGRect
    let keyboardFrame: CGRect
    let sourceFrame: CGRect
  }

  enum Status: Equatable, Sendable {
    case idle
    case overlay
  }

  private(set) var status: Status = .idle

  var isPresentingOverlay: Bool {
    status == .overlay
  }

  @ObservationIgnored let runtime: any HieloRuntimeProviding
  @ObservationIgnored var storage = Storage.idle

  init(runtime: any HieloRuntimeProviding = LiveHieloRuntime()) {
    self.runtime = runtime
  }

  deinit {
    MainActor.assumeIsolated {
      cancel()
    }
  }

  func dismissOverlay() {
    guard case .overlay(let presentation) = storage else { return }
    finishOverlayPresentation(presentation)
  }

  func cancel() {
    let previousStorage = storage
    setStorage(.idle)
    if case .overlay(let presentation) = previousStorage {
      presentation.tearDown()
    }
  }

  func handleOutsideOverlayTap() {
    guard case .overlay(let presentation) = storage else { return }
    presentation.notifyOutsideTap()
  }

  func setStorage(_ storage: Storage) {
    self.storage = storage
    status = storage.status
  }

  enum Storage {
    case idle
    case overlay(HieloOverlayPresentation)

    var status: Status {
      switch self {
      case .idle: .idle
      case .overlay: .overlay
      }
    }
  }
}
