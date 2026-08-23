import CoreGraphics

@MainActor
final class HieloOverlayInteractionRegion {
  var frame: CGRect

  init(frame: CGRect = .zero) {
    self.frame = frame
  }
}
