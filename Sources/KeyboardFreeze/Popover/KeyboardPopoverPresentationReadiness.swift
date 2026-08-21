import CoreGraphics

enum KeyboardPopoverPresentationReadiness {
  static func canPresent(
    isPresented: Bool,
    isHosted: Bool,
    resolvedSourceFrame: CGRect?,
    measuredSourceFrame: CGRect,
    destinationSize: CGSize
  ) -> Bool {
    // Source-window resolution belongs to KeyboardFreeze: keyboard-backed
    // presentation does not require this frame, and it may use a different
    // coordinate space than SwiftUI's placement measurement.
    _ = resolvedSourceFrame

    return isPresented
      && !isHosted
      && !measuredSourceFrame.isEmpty
      && destinationSize.width > 0
      && destinationSize.height > 0
  }
}
