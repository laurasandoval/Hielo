import SwiftUI
import XCTest

@testable import KeyboardFreeze

final class KeyboardPopoverAPITests: XCTestCase {
  @MainActor
  func testModifierAcceptsNonGlassSourceAndShapes() {
    _ = Text("Source")
      .keyboardPopover(
        isPresented: .constant(false),
        sourceGlass: nil,
        sourceShape: .circle,
        popoverShape: .rect(cornerRadius: 28)
      ) {
        Text("Popover")
      }
  }
}
