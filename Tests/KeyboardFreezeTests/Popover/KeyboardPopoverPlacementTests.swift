import SwiftUI
import XCTest

@testable import KeyboardFreeze

final class KeyboardPopoverPlacementTests: XCTestCase {
  func testLeadingAttachmentKeepsLeadingEdgeAndVerticalCenter() {
    let source = CGRect(x: 28, y: 560, width: 48, height: 48)

    let destination = KeyboardPopoverPlacement.destinationFrame(
      sourceFrame: source,
      destinationSize: CGSize(width: 250, height: 250),
      attachmentAnchor: .leading,
      windowBounds: CGRect(x: 0, y: 0, width: 390, height: 844)
    )

    XCTAssertEqual(destination.minX, source.minX, accuracy: 0.001)
    XCTAssertEqual(destination.midY, source.midY, accuracy: 0.001)
  }

  func testAdaptiveLeadingAnchorUsesBottomLeadingForBottomSource() {
    let anchor = KeyboardPopoverPlacement.adaptiveAttachmentAnchor(
      preferredAnchor: .leading,
      sourceFrame: CGRect(x: 28, y: 760, width: 48, height: 48),
      windowBounds: CGRect(x: 0, y: 0, width: 390, height: 844)
    )

    XCTAssertEqual(anchor, .bottomLeading)
  }

  func testAdaptiveTrailingAnchorUsesTopTrailingForTopSource() {
    let anchor = KeyboardPopoverPlacement.adaptiveAttachmentAnchor(
      preferredAnchor: .trailing,
      sourceFrame: CGRect(x: 314, y: 60, width: 48, height: 48),
      windowBounds: CGRect(x: 0, y: 0, width: 390, height: 844)
    )

    XCTAssertEqual(anchor, .topTrailing)
  }

  func testAdaptiveAnchorPreservesExplicitCorner() {
    let anchor = KeyboardPopoverPlacement.adaptiveAttachmentAnchor(
      preferredAnchor: .topLeading,
      sourceFrame: CGRect(x: 314, y: 760, width: 48, height: 48),
      windowBounds: CGRect(x: 0, y: 0, width: 390, height: 844)
    )

    XCTAssertEqual(anchor, .topLeading)
  }

  func testBottomTrailingAttachmentUsesTheMatchingSourceCorner() {
    let source = CGRect(x: 300, y: 500, width: 48, height: 48)

    let destination = KeyboardPopoverPlacement.destinationFrame(
      sourceFrame: source,
      destinationSize: CGSize(width: 200, height: 180),
      attachmentAnchor: .bottomTrailing,
      windowBounds: CGRect(x: 0, y: 0, width: 390, height: 844)
    )

    XCTAssertEqual(destination.maxX, source.maxX, accuracy: 0.001)
    XCTAssertEqual(destination.maxY, source.maxY, accuracy: 0.001)
  }

  func testDestinationStaysInsideWindowBounds() {
    let destination = KeyboardPopoverPlacement.destinationFrame(
      sourceFrame: CGRect(x: 370, y: 830, width: 20, height: 14),
      destinationSize: CGSize(width: 250, height: 250),
      attachmentAnchor: .topLeading,
      windowBounds: CGRect(x: 0, y: 0, width: 390, height: 844)
    )

    XCTAssertEqual(destination.maxX, 390, accuracy: 0.001)
    XCTAssertEqual(destination.maxY, 844, accuracy: 0.001)
  }
}
