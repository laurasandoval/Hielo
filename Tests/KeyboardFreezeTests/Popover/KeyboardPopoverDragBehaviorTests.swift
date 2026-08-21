import CoreGraphics
import XCTest

@testable import KeyboardFreeze

final class KeyboardPopoverDragBehaviorTests: XCTestCase {
  func testRubberBandAllowsEveryDirectionButLimitsTravel() {
    let offset = KeyboardPopoverDragBehavior.rubberBandedOffset(
      for: CGSize(width: -500, height: -500)
    )

    XCTAssertLessThan(offset.width, 0)
    XCTAssertLessThan(offset.height, 0)
    XCTAssertGreaterThan(offset.width, -KeyboardPopoverMotion.horizontalDragLimit)
    XCTAssertGreaterThan(offset.height, -KeyboardPopoverMotion.upwardDragLimit)
  }

  func testOnlyDownwardMotionDismisses() {
    XCTAssertTrue(
      KeyboardPopoverDragBehavior.shouldDismiss(
        translation: CGSize(width: 0, height: 70),
        predictedEndTranslation: CGSize(width: 0, height: 90)
      )
    )
    XCTAssertTrue(
      KeyboardPopoverDragBehavior.shouldDismiss(
        translation: CGSize(width: 0, height: 20),
        predictedEndTranslation: CGSize(width: 0, height: 140)
      )
    )
    XCTAssertFalse(
      KeyboardPopoverDragBehavior.shouldDismiss(
        translation: CGSize(width: 300, height: -20),
        predictedEndTranslation: CGSize(width: 500, height: -80)
      )
    )
  }

  func testVerticalDragCommunicatesDismissalDirectionWithScale() {
    let upwardScale = KeyboardPopoverDragBehavior.scale(
      for: CGSize(width: 0, height: -20)
    )
    let downwardScale = KeyboardPopoverDragBehavior.scale(
      for: CGSize(width: 0, height: 40)
    )

    XCTAssertGreaterThan(upwardScale, 1)
    XCTAssertLessThan(downwardScale, 1)
  }
}
