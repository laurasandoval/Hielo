import SwiftUI
import XCTest

@testable import KeyboardFreeze

final class KeyboardPopoverGeometryTests: XCTestCase {
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

  func testStandardShapesInterpolateBetweenFlexibleSizes() {
    let transition = KeyboardPopoverShapeTransition.standard

    XCTAssertEqual(
      transition.resolve(
        sourceSize: CGSize(width: 48, height: 48),
        destinationSize: CGSize(width: 250, height: 250),
        expansionProgress: 0
      ),
      RectangleCornerRadii(
        topLeading: 24,
        bottomLeading: 24,
        bottomTrailing: 24,
        topTrailing: 24
      )
    )
    XCTAssertEqual(
      transition.resolve(
        sourceSize: CGSize(width: 48, height: 48),
        destinationSize: CGSize(width: 250, height: 250),
        expansionProgress: 0.5
      ),
      RectangleCornerRadii(
        topLeading: 28,
        bottomLeading: 28,
        bottomTrailing: 28,
        topTrailing: 28
      )
    )
    XCTAssertEqual(
      transition.resolve(
        sourceSize: CGSize(width: 48, height: 48),
        destinationSize: CGSize(width: 250, height: 250),
        expansionProgress: 1
      ),
      RectangleCornerRadii(
        topLeading: 32,
        bottomLeading: 32,
        bottomTrailing: 32,
        topTrailing: 32
      )
    )
  }

  func testCustomShapesInterpolateEveryCorner() {
    let transition = KeyboardPopoverShapeTransition(
      sourceShape: .rect(cornerRadius: 8),
      popoverShape: .rect(
        cornerRadii: RectangleCornerRadii(
          topLeading: 32,
          bottomLeading: 24,
          bottomTrailing: 16,
          topTrailing: 8
        )
      )
    )

    XCTAssertEqual(
      transition.resolve(
        sourceSize: CGSize(width: 48, height: 48),
        destinationSize: CGSize(width: 250, height: 250),
        expansionProgress: 0.5
      ),
      RectangleCornerRadii(
        topLeading: 20,
        bottomLeading: 16,
        bottomTrailing: 12,
        topTrailing: 8
      )
    )
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
