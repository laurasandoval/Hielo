import SwiftUI
import XCTest

@testable import Hielo

final class HieloPopoverAPITests: XCTestCase {
  @MainActor
  func testModifierAcceptsNonGlassSourceAndShapes() {
    _ = Text("Source")
      .hieloPopover(
        isPresented: .constant(false),
        sourceGlass: nil,
        sourceShape: .circle,
        popoverShape: .rect(cornerRadius: 28)
      ) {
        Text("Popover")
      }
  }
}
