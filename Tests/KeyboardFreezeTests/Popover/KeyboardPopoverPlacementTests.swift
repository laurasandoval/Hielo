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
      availableBounds: CGRect(x: 0, y: 0, width: 390, height: 844)
    )

    XCTAssertEqual(destination.minX, source.minX, accuracy: 0.001)
    XCTAssertEqual(destination.midY, source.midY, accuracy: 0.001)
  }

  func testAdaptiveLeadingAnchorUsesBottomLeadingForBottomSource() {
    let anchor = KeyboardPopoverPlacement.adaptiveAttachmentAnchor(
      preferredAnchor: .leading,
      sourceFrame: CGRect(x: 28, y: 760, width: 48, height: 48),
      availableBounds: CGRect(x: 0, y: 0, width: 390, height: 844)
    )

    XCTAssertEqual(anchor, .bottomLeading)
  }

  func testAdaptiveTrailingAnchorUsesTopTrailingForTopSource() {
    let anchor = KeyboardPopoverPlacement.adaptiveAttachmentAnchor(
      preferredAnchor: .trailing,
      sourceFrame: CGRect(x: 314, y: 60, width: 48, height: 48),
      availableBounds: CGRect(x: 0, y: 0, width: 390, height: 844)
    )

    XCTAssertEqual(anchor, .topTrailing)
  }

  func testAdaptiveAnchorPreservesExplicitCorner() {
    let anchor = KeyboardPopoverPlacement.adaptiveAttachmentAnchor(
      preferredAnchor: .topLeading,
      sourceFrame: CGRect(x: 314, y: 760, width: 48, height: 48),
      availableBounds: CGRect(x: 0, y: 0, width: 390, height: 844)
    )

    XCTAssertEqual(anchor, .topLeading)
  }

  func testBottomTrailingAttachmentUsesTheMatchingSourceCorner() {
    let source = CGRect(x: 300, y: 500, width: 48, height: 48)

    let destination = KeyboardPopoverPlacement.destinationFrame(
      sourceFrame: source,
      destinationSize: CGSize(width: 200, height: 180),
      attachmentAnchor: .bottomTrailing,
      availableBounds: CGRect(x: 0, y: 0, width: 390, height: 844)
    )

    XCTAssertEqual(destination.maxX, source.maxX, accuracy: 0.001)
    XCTAssertEqual(destination.maxY, source.maxY, accuracy: 0.001)
  }

  func testDestinationStaysInsideAvailableBounds() {
    let destination = KeyboardPopoverPlacement.destinationFrame(
      sourceFrame: CGRect(x: 370, y: 830, width: 20, height: 14),
      destinationSize: CGSize(width: 250, height: 250),
      attachmentAnchor: .topLeading,
      availableBounds: CGRect(x: 0, y: 0, width: 390, height: 844)
    )

    XCTAssertEqual(destination.maxX, 390, accuracy: 0.001)
    XCTAssertEqual(destination.maxY, 844, accuracy: 0.001)
  }

  func testSafeAreaPlacementSnapshots() {
    let snapshots:
      [(
        name: String,
        source: CGRect,
        destinationSize: CGSize,
        anchor: UnitPoint,
        availableBounds: CGRect,
        expected: CGRect
      )] = [
        (
          name: "vertical content taller than the safe area pins to its top edge",
          source: CGRect(x: 16, y: 730, width: 48, height: 48),
          destinationSize: CGSize(width: 250, height: 770),
          anchor: .leading,
          availableBounds: CGRect(x: 0, y: 59, width: 393, height: 759),
          expected: CGRect(x: 16, y: 59, width: 250, height: 770)
        ),
        (
          name: "content wider than the window pins without resizing",
          source: CGRect(x: 329, y: 300, width: 48, height: 48),
          destinationSize: CGSize(width: 770, height: 250),
          anchor: .trailing,
          availableBounds: CGRect(x: 0, y: 59, width: 393, height: 759),
          expected: CGRect(x: 0, y: 199, width: 770, height: 250)
        ),
        (
          name: "top overflow shifts a fitting popover to the safe area",
          source: CGRect(x: 16, y: 100, width: 48, height: 48),
          destinationSize: CGSize(width: 250, height: 250),
          anchor: .leading,
          availableBounds: CGRect(x: 0, y: 59, width: 393, height: 759),
          expected: CGRect(x: 16, y: 59, width: 250, height: 250)
        ),
        (
          name: "bottom overflow uses all remaining safe area",
          source: CGRect(x: 16, y: 750, width: 48, height: 48),
          destinationSize: CGSize(width: 250, height: 250),
          anchor: .leading,
          availableBounds: CGRect(x: 0, y: 59, width: 393, height: 759),
          expected: CGRect(x: 16, y: 568, width: 250, height: 250)
        ),
        (
          name: "trailing overflow uses all remaining safe area",
          source: CGRect(x: 329, y: 300, width: 48, height: 48),
          destinationSize: CGSize(width: 250, height: 250),
          anchor: .trailing,
          availableBounds: CGRect(x: 16, y: 59, width: 361, height: 759),
          expected: CGRect(x: 127, y: 199, width: 250, height: 250)
        ),
      ]

    for snapshot in snapshots {
      let result = KeyboardPopoverPlacement.destinationFrame(
        sourceFrame: snapshot.source,
        destinationSize: snapshot.destinationSize,
        attachmentAnchor: snapshot.anchor,
        availableBounds: snapshot.availableBounds
      )

      XCTAssertEqual(result, snapshot.expected, snapshot.name)
      XCTAssertEqual(result.size, snapshot.destinationSize, snapshot.name)
    }
  }
}
