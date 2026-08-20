import SwiftUI
import XCTest

@testable import KeyboardFreeze

final class KeyboardPopoverGeometryTests: XCTestCase {
  func testStandardCornerRadiiInterpolateBetweenFlexibleSizes() {
    let radii = KeyboardPopoverCornerRadii.standard

    XCTAssertEqual(
      radii.resolve(
        sourceSize: CGSize(width: 48, height: 48),
        destinationSize: CGSize(width: 250, height: 250),
        expansionProgress: 0
      ),
      24
    )
    XCTAssertEqual(
      radii.resolve(
        sourceSize: CGSize(width: 48, height: 48),
        destinationSize: CGSize(width: 250, height: 250),
        expansionProgress: 0.5
      ),
      28
    )
    XCTAssertEqual(
      radii.resolve(
        sourceSize: CGSize(width: 48, height: 48),
        destinationSize: CGSize(width: 250, height: 250),
        expansionProgress: 1
      ),
      32
    )
  }

  func testFixedCornerRadiusClampsToSurfaceSize() {
    let radius = KeyboardPopoverCornerRadii.Radius.fixed(32)

    XCTAssertEqual(radius.resolve(for: CGSize(width: 40, height: 20)), 10)
  }

  func testLeadingAttachmentKeepsLeadingEdgeAndVerticalCenter() {
    let source = CGRect(x: 28, y: 560, width: 48, height: 48)

    let destination = KeyboardPopoverGeometry.destinationFrame(
      sourceFrame: source,
      destinationSize: CGSize(width: 250, height: 250),
      attachmentAnchor: .leading,
      windowBounds: CGRect(x: 0, y: 0, width: 390, height: 844)
    )

    XCTAssertEqual(destination.minX, source.minX, accuracy: 0.001)
    XCTAssertEqual(destination.midY, source.midY, accuracy: 0.001)
  }

  func testBottomTrailingAttachmentUsesTheMatchingSourceCorner() {
    let source = CGRect(x: 300, y: 500, width: 48, height: 48)

    let destination = KeyboardPopoverGeometry.destinationFrame(
      sourceFrame: source,
      destinationSize: CGSize(width: 200, height: 180),
      attachmentAnchor: .bottomTrailing,
      windowBounds: CGRect(x: 0, y: 0, width: 390, height: 844)
    )

    XCTAssertEqual(destination.maxX, source.maxX, accuracy: 0.001)
    XCTAssertEqual(destination.maxY, source.maxY, accuracy: 0.001)
  }

  func testDestinationStaysInsideWindowBounds() {
    let destination = KeyboardPopoverGeometry.destinationFrame(
      sourceFrame: CGRect(x: 370, y: 830, width: 20, height: 14),
      destinationSize: CGSize(width: 250, height: 250),
      attachmentAnchor: .topLeading,
      windowBounds: CGRect(x: 0, y: 0, width: 390, height: 844)
    )

    XCTAssertEqual(destination.maxX, 390, accuracy: 0.001)
    XCTAssertEqual(destination.maxY, 844, accuracy: 0.001)
  }

  func testRubberBandAllowsEveryDirectionButLimitsTravel() {
    let offset = KeyboardPopoverGeometry.rubberBandedOffset(
      for: CGSize(width: -500, height: -500)
    )

    XCTAssertLessThan(offset.width, 0)
    XCTAssertLessThan(offset.height, 0)
    XCTAssertGreaterThan(offset.width, -44)
    XCTAssertGreaterThan(offset.height, -36)
  }

  func testOnlyDownwardMotionDismisses() {
    XCTAssertTrue(
      KeyboardPopoverGeometry.shouldDismiss(
        translation: CGSize(width: 0, height: 70),
        predictedEndTranslation: CGSize(width: 0, height: 90)
      )
    )
    XCTAssertTrue(
      KeyboardPopoverGeometry.shouldDismiss(
        translation: CGSize(width: 0, height: 20),
        predictedEndTranslation: CGSize(width: 0, height: 140)
      )
    )
    XCTAssertFalse(
      KeyboardPopoverGeometry.shouldDismiss(
        translation: CGSize(width: 300, height: -20),
        predictedEndTranslation: CGSize(width: 500, height: -80)
      )
    )
  }

  func testVerticalDragCommunicatesDismissalDirectionWithScale() {
    let upwardScale = KeyboardPopoverGeometry.dragScale(
      for: CGSize(width: 0, height: -20)
    )
    let downwardScale = KeyboardPopoverGeometry.dragScale(
      for: CGSize(width: 0, height: 40)
    )

    XCTAssertGreaterThan(upwardScale, 1)
    XCTAssertLessThan(downwardScale, 1)
  }
}
